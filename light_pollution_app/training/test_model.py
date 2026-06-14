"""Quick test of the trained TFLite model on sample images from each category."""

import os
import numpy as np
from PIL import Image
import tensorflow as tf

MODEL_PATH = os.path.expanduser(
    "~/sura_test/light_pollution_app/assets/sky_quality_model.tflite"
)
DATASET_DIR = os.path.expanduser(
    "~/sura_test/light_pollution_app/training/dataset"
)

CATEGORIES = {
    "cloudy_overcast": 0.05,
    "urban_night": 0.25,
    "suburban_night": 0.50,
    "rural_night": 0.70,
    "clear_dark_night": 0.90,
}


def predict(interpreter, image_path):
    """Run TFLite inference on a single image."""
    img = Image.open(image_path).convert("RGB").resize((224, 224))
    arr = np.array(img, dtype=np.float32)
    arr = (arr / 127.5) - 1.0  # MobileNetV2 preprocessing
    arr = np.expand_dims(arr, 0)

    inp = interpreter.get_input_details()
    out = interpreter.get_output_details()
    interpreter.set_tensor(inp[0]["index"], arr)
    interpreter.invoke()
    score = interpreter.get_tensor(out[0]["index"])[0][0]
    return round(score * 100)


def main():
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()

    print("=" * 60)
    print("  Sky Quality Model — Test Results")
    print("=" * 60)

    for category, expected_score in CATEGORIES.items():
        folder = os.path.join(DATASET_DIR, category)
        if not os.path.isdir(folder):
            print(f"\n  {category}: (no folder)")
            continue

        images = sorted(os.listdir(folder))[:5]  # Test first 5
        if not images:
            print(f"\n  {category}: (no images)")
            continue

        print(f"\n  {category} (expected ~{int(expected_score*100)}):")
        scores = []
        for fname in images:
            path = os.path.join(folder, fname)
            score = predict(interpreter, path)
            scores.append(score)
            print(f"    {fname[:50]:50s} → {score}%")

        avg = sum(scores) / len(scores)
        print(f"    Average: {avg:.0f}%  (expected: {int(expected_score*100)}%)")

    print("\n" + "=" * 60)


if __name__ == "__main__":
    main()
