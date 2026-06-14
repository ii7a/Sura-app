"""
Auto-classify AstroSmartphoneDataset images into training categories.

Analyzes each image's brightness, gray pixel ratio, color, and contrast
to sort into categories for sky quality model training.

Categories:
  - clear_dark_night   (score 0.90) — dark sky, many stars visible
  - rural_night        (score 0.70) — moderate sky, some stars
  - suburban_night     (score 0.50) — light-polluted, few stars
  - urban_night        (score 0.25) — heavy light pollution
  - cloudy_overcast    (score 0.05) — clouds/fog blocking sky
"""

import os
import shutil
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from PIL import Image
import numpy as np

# Source and destination
SRC_DIR = os.path.expanduser(
    "~/Downloads/AstroSmartphoneDataset_images/AstroSmartphoneDataset"
)
DST_DIR = os.path.expanduser(
    "~/sura_test/light_pollution_app/training/dataset"
)

CATEGORIES = {
    "clear_dark_night": 0.90,
    "rural_night": 0.70,
    "suburban_night": 0.50,
    "urban_night": 0.25,
    "cloudy_overcast": 0.05,
}

THUMB_SIZE = (256, 256)


def analyze_image(path):
    """Analyze a single image and return metrics."""
    try:
        img = Image.open(path).convert("RGB")
        img = img.resize(THUMB_SIZE, Image.LANCZOS)
        arr = np.array(img, dtype=np.float64) / 255.0

        r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]

        # Perceived brightness (luminance)
        brightness = 0.299 * r + 0.587 * g + 0.114 * b
        mean_bright = brightness.mean()
        std_bright = brightness.std()

        # Pixel ratios
        dark_ratio = (brightness < 0.08).mean()
        very_dark_ratio = (brightness < 0.03).mean()
        bright_ratio = (brightness > 0.5).mean()

        # Gray detection: low saturation + moderate brightness = clouds/fog
        max_c = np.maximum(r, np.maximum(g, b))
        min_c = np.minimum(r, np.minimum(g, b))
        sat = np.where(max_c > 0, (max_c - min_c) / max_c, 0.0)
        gray_mask = (sat < 0.15) & (brightness >= 0.10) & (brightness <= 0.80)
        gray_ratio = gray_mask.mean()

        # Color ratios
        total = r + g + b + 1e-10
        blue_ratio = (b / total).mean()
        orange_ratio = ((r * 0.7 + g * 0.3) / total).mean()

        # Star-like point detection: bright isolated pixels (high local contrast)
        # Simple approach: count pixels much brighter than their neighbors
        from scipy.ndimage import uniform_filter
        local_mean = uniform_filter(brightness, size=11)
        star_pixels = ((brightness - local_mean) > 0.15).mean()

        return {
            "path": path,
            "mean_bright": mean_bright,
            "std_bright": std_bright,
            "dark_ratio": dark_ratio,
            "very_dark_ratio": very_dark_ratio,
            "bright_ratio": bright_ratio,
            "gray_ratio": gray_ratio,
            "blue_ratio": blue_ratio,
            "orange_ratio": orange_ratio,
            "star_pixels": star_pixels,
        }
    except Exception as e:
        print(f"  Error analyzing {path}: {e}")
        return None


def classify(metrics):
    """Classify an image based on its metrics."""
    m = metrics
    mb = m["mean_bright"]
    gray = m["gray_ratio"]
    dark = m["dark_ratio"]
    very_dark = m["very_dark_ratio"]
    bright = m["bright_ratio"]
    stars = m["star_pixels"]
    std = m["std_bright"]
    orange = m["orange_ratio"]
    blue = m["blue_ratio"]

    # --- Cloudy / Foggy / Overcast ---
    # High gray ratio + moderate brightness = fog or clouds
    if gray > 0.35 and mb > 0.08:
        return "cloudy_overcast"
    # Very bright for a night image = heavy fog/cloud glow
    if mb > 0.35:
        return "cloudy_overcast"
    # High brightness uniformity with moderate brightness = uniform fog
    if mb > 0.15 and std < 0.06 and gray > 0.20:
        return "cloudy_overcast"

    # --- Clear Dark Night ---
    # Very dark overall, many dark pixels, some star points
    if very_dark > 0.60 and mb < 0.06 and stars > 0.001:
        return "clear_dark_night"
    if dark > 0.75 and mb < 0.08 and stars > 0.0005:
        return "clear_dark_night"

    # --- Rural Night ---
    # Mostly dark but some sky glow, stars still detectable
    if dark > 0.50 and mb < 0.12 and stars > 0.0003:
        return "rural_night"
    if very_dark > 0.40 and mb < 0.10:
        return "rural_night"

    # --- Suburban Night ---
    # Moderate brightness, some light pollution glow
    if mb < 0.20 and dark > 0.30:
        return "suburban_night"
    if mb < 0.15 and orange > blue:
        return "suburban_night"

    # --- Urban Night ---
    # Bright sky glow, few dark pixels, orange-shifted
    if mb >= 0.20 or dark < 0.20:
        return "urban_night"
    if bright > 0.15:
        return "urban_night"

    # Default: suburban
    return "suburban_night"


def main():
    # Check scipy
    try:
        import scipy  # noqa: F401
    except ImportError:
        print("Installing scipy...")
        os.system(f"{sys.executable} -m pip install scipy")

    # Create output directories
    for cat in CATEGORIES:
        os.makedirs(os.path.join(DST_DIR, cat), exist_ok=True)

    # Collect all image paths
    image_paths = []
    for root, _, files in os.walk(SRC_DIR):
        for f in files:
            if f.lower().endswith((".jpg", ".jpeg", ".png")):
                image_paths.append(os.path.join(root, f))

    print(f"Found {len(image_paths)} images to classify")

    # Analyze images in parallel
    print("Analyzing images...")
    results = []
    with ProcessPoolExecutor(max_workers=os.cpu_count()) as executor:
        futures = {executor.submit(analyze_image, p): p for p in image_paths}
        done = 0
        for future in as_completed(futures):
            done += 1
            if done % 200 == 0:
                print(f"  Analyzed {done}/{len(image_paths)}...")
            result = future.result()
            if result:
                results.append(result)

    print(f"Successfully analyzed {len(results)} images")

    # Classify and copy
    counts = {cat: 0 for cat in CATEGORIES}
    for metrics in results:
        category = classify(metrics)
        counts[category] += 1
        src = metrics["path"]
        fname = os.path.basename(src)
        # Prefix with phone model to avoid name collisions
        parts = src.split(os.sep)
        for part in parts:
            if part.startswith("pixel"):
                fname = f"{part}_{fname}"
                break
        dst = os.path.join(DST_DIR, category, fname)
        shutil.copy2(src, dst)

    print("\nClassification results:")
    print("-" * 40)
    for cat, count in sorted(counts.items(), key=lambda x: -x[1]):
        score = CATEGORIES[cat]
        print(f"  {cat:25s}: {count:5d} images  (score={score})")
    print(f"  {'TOTAL':25s}: {sum(counts.values()):5d} images")


if __name__ == "__main__":
    main()
