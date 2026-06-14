"""
Train a lightweight neural network on image features for sky quality prediction.

Instead of TFLite (which needs native binaries), we:
1. Extract image features (brightness, color ratios, histograms) from all training images
2. Train a small feedforward neural network on those features
3. Export the weights as Dart code (pure Dart, no native deps!)

This runs in pure Dart, works on ALL platforms (iOS, macOS, Windows, web).
"""

import os
import csv
import numpy as np
from PIL import Image
import json

# Paths
BASE_DIR = "/Users/maii/sura_test/ml_training"
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
LABELS_FILE = os.path.join(DATASET_DIR, "labels.csv")
OUTPUT_DIR = os.path.join(BASE_DIR, "model")
DART_OUTPUT = "/Users/maii/sura_test/light_pollution_app/lib/features/analysis/services/ml_weights.dart"

IMG_SIZE = 224
NUM_FEATURES = 20  # Number of extracted features
HIDDEN1 = 64
HIDDEN2 = 32
EPOCHS = 1500
LEARNING_RATE = 0.003


def extract_features(img_path):
    """Extract numerical features from an image (same approach as Dart pixel analysis)."""
    try:
        img = Image.open(img_path).convert("RGB").resize((100, 100))
        arr = np.array(img, dtype=np.float32) / 255.0

        r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]

        # Perceived brightness
        brightness = 0.299 * r + 0.587 * g + 0.114 * b

        # Basic stats
        mean_bright = float(np.mean(brightness))
        median_bright = float(np.median(brightness))
        std_bright = float(np.std(brightness))
        min_bright = float(np.min(brightness))
        max_bright = float(np.max(brightness))

        # Pixel ratios
        bright_ratio = float(np.mean(brightness > 0.6))
        dark_ratio = float(np.mean(brightness < 0.15))
        very_dark_ratio = float(np.mean(brightness < 0.05))
        mid_ratio = float(np.mean((brightness > 0.2) & (brightness < 0.5)))

        # Color analysis
        total = r + g + b + 1e-7
        blue_ratio = float(np.mean(b / total))
        red_ratio = float(np.mean(r / total))
        green_ratio = float(np.mean(g / total))
        orange_ratio = float(np.mean((r * 0.7 + g * 0.3) / total))

        # Color temperature indicator (blue vs red dominance)
        color_temp = float(np.mean(b - r))

        # Uniformity (low std = uniform lighting = light pollution)
        uniformity = 1.0 - min(std_bright * 3, 1.0)

        # Histogram features (bin into 8 groups)
        hist, _ = np.histogram(brightness.flatten(), bins=8, range=(0, 1))
        hist = hist.astype(float) / hist.sum()

        # Top brightness percentiles
        p90 = float(np.percentile(brightness, 90))
        p10 = float(np.percentile(brightness, 10))

        features = [
            mean_bright, median_bright, std_bright,
            bright_ratio, dark_ratio, very_dark_ratio, mid_ratio,
            blue_ratio, red_ratio, orange_ratio,
            color_temp, uniformity,
            p90, p10,
            min_bright, max_bright,
            hist[0], hist[1],  # Dark bins
            hist[6], hist[7],  # Bright bins
        ]

        return features
    except Exception as e:
        print(f"Error: {e}")
        return None


def relu(x):
    return np.maximum(0, x)


def sigmoid(x):
    return 1.0 / (1.0 + np.exp(-np.clip(x, -500, 500)))


class NeuralNet:
    """Simple 3-layer feedforward neural network."""

    def __init__(self, input_size, hidden1, hidden2):
        # Xavier initialization
        self.w1 = np.random.randn(input_size, hidden1) * np.sqrt(2.0 / input_size)
        self.b1 = np.zeros(hidden1)
        self.w2 = np.random.randn(hidden1, hidden2) * np.sqrt(2.0 / hidden1)
        self.b2 = np.zeros(hidden2)
        self.w3 = np.random.randn(hidden2, 1) * np.sqrt(2.0 / hidden2)
        self.b3 = np.zeros(1)

    def forward(self, x):
        self.z1 = x @ self.w1 + self.b1
        self.a1 = relu(self.z1)
        self.z2 = self.a1 @ self.w2 + self.b2
        self.a2 = relu(self.z2)
        self.z3 = self.a2 @ self.w3 + self.b3
        self.out = sigmoid(self.z3)
        return self.out

    def backward(self, x, y, lr):
        batch_size = x.shape[0]

        # Output gradient
        d_out = (self.out - y) / batch_size  # MSE derivative

        # Layer 3
        d_w3 = self.a2.T @ d_out
        d_b3 = np.sum(d_out, axis=0)

        # Layer 2
        d_a2 = d_out @ self.w3.T
        d_z2 = d_a2 * (self.z2 > 0)  # ReLU derivative
        d_w2 = self.a1.T @ d_z2
        d_b2 = np.sum(d_z2, axis=0)

        # Layer 1
        d_a1 = d_z2 @ self.w2.T
        d_z1 = d_a1 * (self.z1 > 0)
        d_w1 = x.T @ d_z1
        d_b1 = np.sum(d_z1, axis=0)

        # Update
        self.w1 -= lr * d_w1
        self.b1 -= lr * d_b1
        self.w2 -= lr * d_w2
        self.b2 -= lr * d_b2
        self.w3 -= lr * d_w3
        self.b3 -= lr * d_b3

    def loss(self, y_pred, y_true):
        return float(np.mean((y_pred - y_true) ** 2))


def export_to_dart(net, feature_means, feature_stds):
    """Export neural network weights as Dart source code."""
    def array_to_dart(arr, name):
        flat = arr.flatten().tolist()
        values = ", ".join(f"{v:.8f}" for v in flat)
        return f"  static const {name} = [{values}];"

    def shape_comment(arr):
        return f"// Shape: {arr.shape}"

    dart_code = f"""// AUTO-GENERATED — Do not edit manually.
// Trained neural network weights for sky quality prediction.
// Input: {NUM_FEATURES} image features → Output: sky quality 0-100
// Architecture: {NUM_FEATURES} → {HIDDEN1} (ReLU) → {HIDDEN2} (ReLU) → 1 (Sigmoid)

class MlWeights {{
  // Feature normalization (mean and std from training data)
  {array_to_dart(feature_means, 'featureMeans')}
  {array_to_dart(feature_stds, 'featureStds')}

  // Layer 1: {NUM_FEATURES} → {HIDDEN1} {shape_comment(net.w1)}
  {array_to_dart(net.w1, 'w1')}
  {array_to_dart(net.b1, 'b1')}

  // Layer 2: {HIDDEN1} → {HIDDEN2} {shape_comment(net.w2)}
  {array_to_dart(net.w2, 'w2')}
  {array_to_dart(net.b2, 'b2')}

  // Layer 3: {HIDDEN2} → 1 {shape_comment(net.w3)}
  {array_to_dart(net.w3, 'w3')}
  {array_to_dart(net.b3, 'b3')}

  static const inputSize = {NUM_FEATURES};
  static const hidden1Size = {HIDDEN1};
  static const hidden2Size = {HIDDEN2};
}}
"""
    os.makedirs(os.path.dirname(DART_OUTPUT), exist_ok=True)
    with open(DART_OUTPUT, "w") as f:
        f.write(dart_code)
    print(f"Dart weights exported to: {DART_OUTPUT}")


def main():
    print("=" * 60)
    print("SURA Sky Quality - Pure Dart Neural Network Training")
    print(f"Features: {NUM_FEATURES} → {HIDDEN1} → {HIDDEN2} → 1")
    print("=" * 60)

    # Extract features from all images
    print("\n[1/4] Extracting features from images...")
    X_list = []
    y_list = []

    with open(LABELS_FILE, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            img_path = os.path.join(DATASET_DIR, row["filename"])
            score = float(row["score"]) / 100.0

            if not os.path.exists(img_path):
                continue

            features = extract_features(img_path)
            if features is not None:
                X_list.append(features)
                y_list.append([score])

    X = np.array(X_list, dtype=np.float64)
    y = np.array(y_list, dtype=np.float64)
    print(f"  Extracted features from {len(X)} images")
    print(f"  Feature shape: {X.shape}")

    # Normalize features
    feature_means = X.mean(axis=0)
    feature_stds = X.std(axis=0) + 1e-7
    X_norm = (X - feature_means) / feature_stds

    # Train/test split
    indices = np.random.permutation(len(X_norm))
    split = int(0.85 * len(indices))
    train_idx = indices[:split]
    test_idx = indices[split:]

    X_train, y_train = X_norm[train_idx], y[train_idx]
    X_test, y_test = X_norm[test_idx], y[test_idx]
    print(f"  Train: {len(X_train)}, Test: {len(X_test)}")

    # Train
    print(f"\n[2/4] Training ({EPOCHS} epochs)...")
    net = NeuralNet(NUM_FEATURES, HIDDEN1, HIDDEN2)

    best_test_loss = float("inf")
    best_weights = None

    for epoch in range(EPOCHS):
        # Forward + backward on full training set
        pred = net.forward(X_train)
        net.backward(X_train, y_train, LEARNING_RATE)
        train_loss = net.loss(pred, y_train)

        # Test
        test_pred = net.forward(X_test)
        test_loss = net.loss(test_pred, y_test)

        if test_loss < best_test_loss:
            best_test_loss = test_loss
            best_weights = (
                net.w1.copy(), net.b1.copy(),
                net.w2.copy(), net.b2.copy(),
                net.w3.copy(), net.b3.copy(),
            )

        if (epoch + 1) % 50 == 0:
            train_mae = float(np.mean(np.abs(pred - y_train))) * 100
            test_mae = float(np.mean(np.abs(test_pred - y_test))) * 100
            print(f"  Epoch {epoch+1:4d}: Train MAE={train_mae:.1f}, Test MAE={test_mae:.1f}")

    # Restore best weights
    net.w1, net.b1, net.w2, net.b2, net.w3, net.b3 = best_weights

    # Final evaluation
    print(f"\n[3/4] Final evaluation...")
    test_pred = net.forward(X_test)
    test_mae = float(np.mean(np.abs(test_pred - y_test))) * 100
    print(f"  Best Test MAE: {test_mae:.1f} points (on 0-100 scale)")

    print(f"\n  Sample predictions:")
    for i in range(min(10, len(X_test))):
        pred_score = int(test_pred[i][0] * 100)
        actual_score = int(y_test[i][0] * 100)
        print(f"    Predicted={pred_score:3d}, Actual={actual_score:3d}, Error={abs(pred_score - actual_score)}")

    # Export to Dart
    print(f"\n[4/4] Exporting to Dart...")
    export_to_dart(net, feature_means, feature_stds)

    print(f"\n{'=' * 60}")
    print("Training complete!")
    print(f"Model: {NUM_FEATURES} features → {HIDDEN1} → {HIDDEN2} → 1 neuron")
    print(f"Test MAE: {test_mae:.1f} points on 0-100 scale")
    print(f"Weights exported as pure Dart code (no native dependencies!)")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    np.random.seed(42)
    main()
