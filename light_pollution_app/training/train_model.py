"""
SURA Sky Quality Model — Training Pipeline

Trains a MobileNetV2-based regression model on sky photos categorised
by Bortle scale, then exports a TFLite model that drops straight into
the Flutter app's assets/ folder.

Directory layout expected:
    dataset/
        bortle_1_3/   ← dark skies (Milky Way visible, stars everywhere)
        bortle_4_5/   ← suburban (some stars, light domes on horizon)
        bortle_6_7/   ← urban (few stars, orange/white sky glow)
        bortle_8_9/   ← city centre (almost no stars, bright sky)

Each folder should contain ~50-100 JPEG/PNG sky photos.

Output scale: 0.0 = heavy light pollution, 1.0 = pristine dark sky
(The Flutter app multiplies by 100 to get a 0-100 score.)
"""

import os
import sys
import shutil
import random
import numpy as np
from PIL import Image
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# ── Paths ────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(SCRIPT_DIR, "dataset")
ASSETS_DIR = os.path.join(SCRIPT_DIR, "..", "assets")
TFLITE_OUTPUT = os.path.join(ASSETS_DIR, "sky_quality_model.tflite")

# ── Hyper-parameters ─────────────────────────────────────────────────
IMG_SIZE = 224
BATCH_SIZE = 16
EPOCHS_FROZEN = 15       # Phase 1: only top layers
EPOCHS_FINETUNE = 15     # Phase 2: unfreeze last 30 base layers
LR_FROZEN = 1e-3
LR_FINETUNE = 1e-5
VAL_SPLIT = 0.20
SEED = 42

# ── Folder → target score mapping ───────────────────────────────────
# Higher = better sky quality (matches app convention)
FOLDER_SCORES = {
    "clear_dark_night": 0.90,   # Pristine dark sky, stars everywhere
    "rural_night":      0.70,   # Mostly dark, some sky glow
    "suburban_night":   0.50,   # Moderate light pollution
    "urban_night":      0.25,   # Heavy light pollution
    "cloudy_overcast":  0.05,   # Clouds/fog — not suitable for stargazing
}

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


# ── Data loading ─────────────────────────────────────────────────────
def load_dataset():
    """Walk the four dataset folders and return (images, scores) arrays."""
    images, scores = [], []

    for folder, score in FOLDER_SCORES.items():
        folder_path = os.path.join(DATASET_DIR, folder)
        if not os.path.isdir(folder_path):
            print(f"  WARNING: folder missing — {folder_path}")
            continue

        count = 0
        for fname in sorted(os.listdir(folder_path)):
            if os.path.splitext(fname)[1].lower() not in IMAGE_EXTENSIONS:
                continue
            fpath = os.path.join(folder_path, fname)
            try:
                img = Image.open(fpath).convert("RGB").resize((IMG_SIZE, IMG_SIZE))
                arr = np.array(img, dtype=np.float32)
                # MobileNetV2 preprocessing: scale to [-1, 1]
                arr = (arr / 127.5) - 1.0
                images.append(arr)
                scores.append(score)
                count += 1
            except Exception as e:
                print(f"  Skipping {fpath}: {e}")

        print(f"  {folder}: {count} images  (target score = {score})")

    return np.array(images), np.array(scores, dtype=np.float32)


# ── Data augmentation ────────────────────────────────────────────────
def build_augmentation():
    """Keras preprocessing layers for on-the-fly augmentation."""
    return keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.05),
        layers.RandomBrightness(factor=0.15),
    ], name="augmentation")


# ── Model construction ───────────────────────────────────────────────
def build_model():
    """MobileNetV2 base + regression head."""
    base = keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )
    base.trainable = False  # Freeze for Phase 1

    augmentation = build_augmentation()

    inputs = keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    x = augmentation(inputs)
    x = base(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.2)(x)
    x = layers.Dense(64, activation="relu")(x)
    outputs = layers.Dense(1, activation="sigmoid")(x)

    model = keras.Model(inputs, outputs)

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LR_FROZEN),
        loss="mse",
        metrics=["mae"],
    )

    return model, base


# ── TFLite conversion ───────────────────────────────────────────────
def convert_to_tflite(model):
    """Export the trained Keras model to TFLite with float16 quantisation."""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_bytes = converter.convert()

    os.makedirs(os.path.dirname(TFLITE_OUTPUT), exist_ok=True)
    with open(TFLITE_OUTPUT, "wb") as f:
        f.write(tflite_bytes)

    size_mb = len(tflite_bytes) / (1024 * 1024)
    print(f"  Saved: {TFLITE_OUTPUT}  ({size_mb:.2f} MB)")
    return TFLITE_OUTPUT


# ── TFLite verification ─────────────────────────────────────────────
def verify_tflite(tflite_path, images, scores, n=10):
    """Run a few samples through the TFLite model and print results."""
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()
    out = interpreter.get_output_details()

    n = min(n, len(images))
    errors = []

    for i in range(n):
        interpreter.set_tensor(inp[0]["index"],
                               np.expand_dims(images[i], 0).astype(np.float32))
        interpreter.invoke()
        pred = interpreter.get_tensor(out[0]["index"])[0][0]
        err = abs(pred - scores[i]) * 100
        errors.append(err)
        print(f"    Sample {i+1}: predicted={pred*100:.0f}  actual={scores[i]*100:.0f}  err={err:.1f}")

    print(f"  Average error: {np.mean(errors):.1f} pts (on 0-100 scale)")


# ── Main pipeline ────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("  SURA — Sky Quality Model Training Pipeline")
    print("  MobileNetV2 transfer learning → TFLite")
    print("=" * 60)

    # ── 1. Load dataset ──────────────────────────────────────────────
    print("\n[1/6] Loading dataset...")
    images, scores = load_dataset()

    if len(images) < 20:
        print(f"\n  ERROR: Only {len(images)} images found. Need at least 20.")
        print("  Fill the dataset/ folders with sky photos first.")
        print("  See the README at the top of this script for guidance.")
        sys.exit(1)

    print(f"\n  Total: {len(images)} images")
    print(f"  Score range: {scores.min():.3f} – {scores.max():.3f}")

    # ── 2. Train / val split ─────────────────────────────────────────
    print("\n[2/6] Splitting data...")
    random.seed(SEED)
    indices = list(range(len(images)))
    random.shuffle(indices)
    split = int(len(indices) * (1 - VAL_SPLIT))

    X_train, y_train = images[indices[:split]], scores[indices[:split]]
    X_val, y_val = images[indices[split:]], scores[indices[split:]]
    print(f"  Train: {len(X_train)}   Val: {len(X_val)}")

    # ── 3. Build model ───────────────────────────────────────────────
    print("\n[3/6] Building model...")
    model, base = build_model()
    model.summary()

    # ── 4. Phase 1 — frozen base ─────────────────────────────────────
    print(f"\n[4/6] Phase 1: training top layers ({EPOCHS_FROZEN} epochs)...")
    model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS_FROZEN,
        batch_size=BATCH_SIZE,
    )

    # ── 5. Phase 2 — fine-tune ───────────────────────────────────────
    print(f"\n[5/6] Phase 2: fine-tuning last 30 base layers ({EPOCHS_FINETUNE} epochs)...")
    base.trainable = True
    for layer in base.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LR_FINETUNE),
        loss="mse",
        metrics=["mae"],
    )

    model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS_FINETUNE,
        batch_size=BATCH_SIZE,
    )

    # ── 6. Evaluate, convert, verify ─────────────────────────────────
    print("\n[6/6] Evaluating & exporting...")
    loss, mae = model.evaluate(X_val, y_val, verbose=0)
    print(f"  Val MSE:  {loss:.4f}")
    print(f"  Val MAE:  {mae:.4f}  ({mae*100:.1f} pts on 0-100 scale)")

    tflite_path = convert_to_tflite(model)

    print("\n  TFLite verification:")
    verify_tflite(tflite_path, X_val, y_val)

    print("\n" + "=" * 60)
    print("  Training complete!")
    print(f"  Model deployed to: {TFLITE_OUTPUT}")
    print("  Rebuild the Flutter app to use the new model.")
    print("=" * 60)


if __name__ == "__main__":
    main()
