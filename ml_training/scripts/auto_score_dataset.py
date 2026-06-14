"""
Auto-score images using heuristic pixel analysis for more accurate labels.
Instead of random scores within a range, this analyzes each image's actual
brightness/color to assign a realistic sky quality score.
"""

import os
import csv
import numpy as np
from PIL import Image

DATASET_DIR = "/Users/maii/sura_test/ml_training/dataset"
LABELS_FILE = os.path.join(DATASET_DIR, "labels.csv")

# Score ranges per category (used as guardrails)
CATEGORY_RANGES = {
    "dark_sky": (70, 100),
    "rural": (50, 78),
    "suburban": (35, 60),
    "urban": (15, 42),
    "city_center": (0, 20),
    "cloudy": (0, 15),
    "rainy": (0, 10),
    "sunny": (0, 5),
}


def analyze_image(img_path):
    """Analyze image brightness/color and return a raw quality estimate."""
    try:
        img = Image.open(img_path).convert("RGB").resize((100, 100))
        arr = np.array(img, dtype=np.float32) / 255.0

        r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
        brightness = 0.299 * r + 0.587 * g + 0.114 * b

        mean_bright = float(np.mean(brightness))
        std_bright = float(np.std(brightness))
        bright_ratio = float(np.mean(brightness > 0.6))
        dark_ratio = float(np.mean(brightness < 0.15))
        very_dark_ratio = float(np.mean(brightness < 0.05))

        total = r + g + b + 1e-7
        blue_ratio = float(np.mean(b / total))
        red_ratio = float(np.mean(r / total))
        orange_ratio = float(np.mean((r * 0.7 + g * 0.3) / total))

        # Detect if image is "gray" (cloudy/overcast)
        max_ch = np.maximum(np.maximum(r, g), b)
        min_ch = np.minimum(np.minimum(r, g), b)
        saturation = np.where(max_ch > 0.01, (max_ch - min_ch) / (max_ch + 1e-7), 0)
        mean_sat = float(np.mean(saturation))
        gray_ratio = float(np.mean((saturation < 0.15) & (brightness > 0.1) & (brightness < 0.7)))

        return {
            "mean_bright": mean_bright,
            "std_bright": std_bright,
            "bright_ratio": bright_ratio,
            "dark_ratio": dark_ratio,
            "very_dark_ratio": very_dark_ratio,
            "blue_ratio": blue_ratio,
            "red_ratio": red_ratio,
            "orange_ratio": orange_ratio,
            "mean_sat": mean_sat,
            "gray_ratio": gray_ratio,
        }
    except Exception as e:
        print(f"  Error analyzing {img_path}: {e}")
        return None


def compute_heuristic_score(metrics):
    """Compute a raw sky quality score from image metrics."""
    m = metrics

    # Very bright = daytime or heavy light pollution
    if m["mean_bright"] > 0.4:
        return max(0, 5 - int(m["mean_bright"] * 10))

    # Gray/overcast detection
    if m["gray_ratio"] > 0.4 and m["mean_bright"] > 0.1:
        return max(0, int((1 - m["gray_ratio"]) * 15))

    # Base score from darkness
    darkness_score = m["dark_ratio"] * 40 + m["very_dark_ratio"] * 30

    # Penalty for bright pixels (light pollution glow)
    bright_penalty = m["bright_ratio"] * 50

    # Bonus for blue-ish sky (natural night sky is slightly blue)
    blue_bonus = max(0, (m["blue_ratio"] - 0.33)) * 30

    # Penalty for orange/red glow (artificial light pollution)
    orange_penalty = max(0, (m["orange_ratio"] - 0.25)) * 40

    # Penalty for uniformity (uniform glow = light pollution)
    uniformity = 1.0 - min(m["std_bright"] * 3, 1.0)
    uniformity_penalty = uniformity * 15 if m["mean_bright"] > 0.05 else 0

    score = darkness_score - bright_penalty + blue_bonus - orange_penalty - uniformity_penalty

    # Scale to 0-100
    score = max(0, min(100, int(score * 1.5 + 20)))

    return score


def clamp_to_category(score, category):
    """Clamp the heuristic score to the expected category range."""
    if category not in CATEGORY_RANGES:
        return score

    lo, hi = CATEGORY_RANGES[category]
    # Allow some flexibility: use weighted blend between heuristic and category center
    center = (lo + hi) / 2
    # 70% heuristic, 30% category center, then clamp
    blended = int(score * 0.7 + center * 0.3)
    return max(lo, min(hi, blended))


def main():
    print("=" * 60)
    print("SURA — Auto-Score Dataset Images")
    print("=" * 60)

    # Read current labels
    entries = []
    with open(LABELS_FILE, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            entries.append({"filename": row["filename"], "score": int(row["score"])})

    print(f"\nTotal images: {len(entries)}")
    print("\nAnalyzing and re-scoring...")

    updated = 0
    category_stats = {}

    for entry in entries:
        img_path = os.path.join(DATASET_DIR, entry["filename"])
        if not os.path.exists(img_path):
            continue

        # Determine category from filename path
        category = entry["filename"].split("/")[0]

        metrics = analyze_image(img_path)
        if metrics is None:
            continue

        heuristic_score = compute_heuristic_score(metrics)
        new_score = clamp_to_category(heuristic_score, category)

        if category not in category_stats:
            category_stats[category] = {"scores": [], "old_scores": []}

        category_stats[category]["old_scores"].append(entry["score"])
        category_stats[category]["scores"].append(new_score)

        entry["score"] = new_score
        updated += 1

    # Write updated labels
    with open(LABELS_FILE, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["filename", "score"])
        for entry in entries:
            writer.writerow([entry["filename"], entry["score"]])

    print(f"\nRe-scored {updated} images")
    print(f"\nCategory score distributions:")
    for cat in sorted(category_stats.keys()):
        s = category_stats[cat]
        scores = s["scores"]
        old = s["old_scores"]
        print(f"  {cat:15s}: {len(scores):4d} imgs | "
              f"old avg={np.mean(old):5.1f} | "
              f"new avg={np.mean(scores):5.1f} | "
              f"range [{min(scores)}-{max(scores)}]")

    print(f"\nLabels updated: {LABELS_FILE}")
    print("Next: Retrain with train_dart_model.py")


if __name__ == "__main__":
    main()
