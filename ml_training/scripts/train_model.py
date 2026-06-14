"""
Train a MobileNetV2-based regression model for sky quality prediction.

Input: 224x224 RGB image of the sky
Output: Score 0-100 (0 = heavy light pollution, 100 = pristine dark sky)

Uses transfer learning from MobileNetV2 (pretrained on ImageNet).
Converts to TFLite for Flutter deployment.
"""

import os
import csv
import numpy as np
from PIL import Image
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import random

# Paths
BASE_DIR = "/Users/maii/sura_test/ml_training"
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
LABELS_FILE = os.path.join(DATASET_DIR, "labels.csv")
MODEL_DIR = os.path.join(BASE_DIR, "model")
TFLITE_PATH = os.path.join(MODEL_DIR, "sky_quality_model.tflite")

# Hyperparameters
IMG_SIZE = 224
BATCH_SIZE = 16
EPOCHS_FROZEN = 15     # Train only top layers first
EPOCHS_FINETUNE = 20   # Fine-tune last few layers
LEARNING_RATE = 1e-3
FINETUNE_LR = 1e-5


def load_dataset():
    """Load images and labels from CSV."""
    images = []
    scores = []

    with open(LABELS_FILE, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            img_path = os.path.join(DATASET_DIR, row["filename"])
            score = float(row["score"])

            if not os.path.exists(img_path):
                continue

            try:
                img = Image.open(img_path).convert("RGB").resize((IMG_SIZE, IMG_SIZE))
                arr = np.array(img, dtype=np.float32)
                # MobileNetV2 preprocessing: scale to [-1, 1]
                arr = (arr / 127.5) - 1.0
                images.append(arr)
                scores.append(score / 100.0)  # Normalize to 0-1 for training
            except Exception as e:
                print(f"  Skipping {row['filename']}: {e}")

    return np.array(images), np.array(scores)


def build_model():
    """Build MobileNetV2-based regression model."""
    # Load pretrained MobileNetV2 (without top classification layer)
    base_model = keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )

    # Freeze base model initially
    base_model.trainable = False

    # Build regression head
    model = keras.Sequential([
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.3),
        layers.Dense(128, activation="relu"),
        layers.Dropout(0.2),
        layers.Dense(64, activation="relu"),
        layers.Dense(1, activation="sigmoid"),  # Output 0-1
    ])

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss="mse",
        metrics=["mae"],
    )

    return model, base_model


def convert_to_tflite(model):
    """Convert Keras model to TFLite."""
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()

    os.makedirs(MODEL_DIR, exist_ok=True)
    with open(TFLITE_PATH, "wb") as f:
        f.write(tflite_model)

    size_mb = os.path.getsize(TFLITE_PATH) / (1024 * 1024)
    print(f"\nTFLite model saved: {TFLITE_PATH}")
    print(f"Model size: {size_mb:.2f} MB")
    return TFLITE_PATH


def test_tflite_model(tflite_path, test_images, test_scores):
    """Test the TFLite model on a few samples."""
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"\nTFLite Model Test (on {min(10, len(test_images))} samples):")
    print("-" * 50)

    errors = []
    for i in range(min(10, len(test_images))):
        input_data = np.expand_dims(test_images[i], axis=0).astype(np.float32)
        interpreter.set_tensor(input_details[0]["index"], input_data)
        interpreter.invoke()
        prediction = interpreter.get_tensor(output_details[0]["index"])[0][0]

        predicted_score = int(prediction * 100)
        actual_score = int(test_scores[i] * 100)
        error = abs(predicted_score - actual_score)
        errors.append(error)

        print(f"  Sample {i+1}: Predicted={predicted_score}, Actual={actual_score}, Error={error}")

    avg_error = sum(errors) / len(errors)
    print(f"\nAverage Error: {avg_error:.1f} points (on 0-100 scale)")


def main():
    print("=" * 60)
    print("SURA Sky Quality Model Training")
    print("MobileNetV2 Transfer Learning → TFLite")
    print("=" * 60)

    # Load data
    print("\n[1/5] Loading dataset...")
    images, scores = load_dataset()
    print(f"  Loaded {len(images)} images")
    print(f"  Score range: {scores.min()*100:.0f} - {scores.max()*100:.0f}")

    # Shuffle and split
    indices = list(range(len(images)))
    random.shuffle(indices)
    split = int(0.85 * len(indices))

    train_idx = indices[:split]
    test_idx = indices[split:]

    X_train, y_train = images[train_idx], scores[train_idx]
    X_test, y_test = images[test_idx], scores[test_idx]

    print(f"  Train: {len(X_train)}, Test: {len(X_test)}")

    # Build model
    print("\n[2/5] Building MobileNetV2 model...")
    model, base_model = build_model()
    model.summary()

    # Phase 1: Train top layers (base frozen)
    print(f"\n[3/5] Phase 1: Training top layers ({EPOCHS_FROZEN} epochs)...")
    history1 = model.fit(
        X_train, y_train,
        validation_data=(X_test, y_test),
        epochs=EPOCHS_FROZEN,
        batch_size=BATCH_SIZE,
        verbose=1,
    )

    # Phase 2: Fine-tune last layers of base model
    print(f"\n[4/5] Phase 2: Fine-tuning ({EPOCHS_FINETUNE} epochs)...")
    base_model.trainable = True
    # Freeze all layers except last 30
    for layer in base_model.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=FINETUNE_LR),
        loss="mse",
        metrics=["mae"],
    )

    history2 = model.fit(
        X_train, y_train,
        validation_data=(X_test, y_test),
        epochs=EPOCHS_FINETUNE,
        batch_size=BATCH_SIZE,
        verbose=1,
    )

    # Evaluate
    print("\n[5/5] Evaluating and converting...")
    loss, mae = model.evaluate(X_test, y_test, verbose=0)
    print(f"  Test Loss (MSE): {loss:.4f}")
    print(f"  Test MAE: {mae:.4f} (= {mae*100:.1f} points on 0-100 scale)")

    # Convert to TFLite
    tflite_path = convert_to_tflite(model)

    # Test TFLite model
    test_tflite_model(tflite_path, X_test, y_test)

    # Also save the Keras model
    keras_path = os.path.join(MODEL_DIR, "sky_quality_model.keras")
    model.save(keras_path)
    print(f"\nKeras model saved: {keras_path}")

    print("\n" + "=" * 60)
    print("Training complete!")
    print(f"TFLite model ready at: {tflite_path}")
    print("=" * 60)


if __name__ == "__main__":
    main()
