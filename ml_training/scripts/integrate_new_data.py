"""
Integrate images from 'Sky pic for traininig' into the ML training dataset.

Category mapping (sky quality score for stargazing, 0-100):
  - night dark  → dark_sky    (80-100) — pristine dark skies, great for stargazing
  - night urban → urban       (15-40)  — light-polluted night skies
  - cloudy      → cloudy      (0-12)   — can't see stars through clouds
  - rainy       → rainy       (0-8)    — worst conditions for stargazing
  - sunny       → sunny       (0-5)    — daytime, no stargazing possible
"""

import os
import shutil
import csv
import random
from PIL import Image

# Paths
SKY_PIC_DIR = "/Users/maii/Sky pic for traininig"
DATASET_DIR = "/Users/maii/sura_test/ml_training/dataset"
LABELS_FILE = os.path.join(DATASET_DIR, "labels.csv")
LABELS_BACKUP = os.path.join(DATASET_DIR, "labels_backup_original.csv")

# Category mapping: source_folder → (target_folder, score_min, score_max)
CATEGORY_MAP = {
    "night dark": ("dark_sky", 80, 100),
    "night urban": ("urban", 15, 40),
    "cloudy": ("cloudy", 0, 12),
    "rainy": ("rainy", 0, 8),
    "sunny ((sunrise, sunset, and sunny are all daytime — can't stargaze)": ("sunny", 0, 5),
}

# Max images per category to keep dataset balanced
# (night dark has 5000+, so we cap it)
MAX_PER_CATEGORY = 250

VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp"}


def get_image_files(directory):
    """Get all valid image files in a directory."""
    files = []
    for f in os.listdir(directory):
        ext = os.path.splitext(f)[1].lower()
        if ext in VALID_EXTENSIONS:
            files.append(f)
    return sorted(files)


def validate_image(path):
    """Check if image is valid and can be opened."""
    try:
        with Image.open(path) as img:
            img.verify()
        return True
    except Exception:
        return False


def load_existing_labels():
    """Load existing labels.csv entries."""
    entries = []
    if os.path.exists(LABELS_FILE):
        with open(LABELS_FILE, "r") as f:
            reader = csv.DictReader(f)
            for row in reader:
                entries.append((row["filename"], int(row["score"])))
    return entries


def main():
    random.seed(42)

    print("=" * 60)
    print("SURA — Integrate 'Sky pic for traininig' into Dataset")
    print("=" * 60)

    # Backup existing labels
    if os.path.exists(LABELS_FILE) and not os.path.exists(LABELS_BACKUP):
        shutil.copy2(LABELS_FILE, LABELS_BACKUP)
        print(f"\nBacked up original labels to: {LABELS_BACKUP}")

    # Load existing entries
    existing = load_existing_labels()
    print(f"\nExisting dataset: {len(existing)} images")

    new_entries = []
    total_copied = 0
    stats = {}

    for src_folder, (target_folder, score_min, score_max) in CATEGORY_MAP.items():
        src_path = os.path.join(SKY_PIC_DIR, src_folder)
        if not os.path.exists(src_path):
            print(f"\n  WARNING: Source folder not found: {src_path}")
            continue

        # Create target directory
        target_path = os.path.join(DATASET_DIR, target_folder)
        os.makedirs(target_path, exist_ok=True)

        # Get all images
        all_images = get_image_files(src_path)
        print(f"\n[{src_folder}] → {target_folder} (score {score_min}-{score_max})")
        print(f"  Found {len(all_images)} images")

        # Sample if too many
        if len(all_images) > MAX_PER_CATEGORY:
            selected = random.sample(all_images, MAX_PER_CATEGORY)
            print(f"  Sampling {MAX_PER_CATEGORY} of {len(all_images)} (balanced)")
        else:
            selected = all_images
            print(f"  Using all {len(selected)} images")

        # Find the next index for this category
        existing_files = os.listdir(target_path) if os.path.exists(target_path) else []
        existing_indices = []
        for ef in existing_files:
            name = os.path.splitext(ef)[0]
            parts = name.split("_")
            # Extract numeric part (e.g., dark_sky_014 → 14)
            for p in reversed(parts):
                if p.isdigit():
                    existing_indices.append(int(p))
                    break
        next_idx = max(existing_indices, default=-1) + 1

        copied = 0
        skipped = 0
        for img_file in selected:
            src_img = os.path.join(src_path, img_file)

            # Validate image
            if not validate_image(src_img):
                skipped += 1
                continue

            # Generate new filename
            new_name = f"{target_folder}_{next_idx:04d}.jpg"
            dst_img = os.path.join(target_path, new_name)

            # Copy and convert to jpg
            try:
                with Image.open(src_img) as img:
                    img = img.convert("RGB")
                    img.save(dst_img, "JPEG", quality=95)
            except Exception as e:
                print(f"    Error copying {img_file}: {e}")
                skipped += 1
                continue

            # Assign a random score within the category range
            score = random.randint(score_min, score_max)

            new_entries.append((f"{target_folder}/{new_name}", score))
            next_idx += 1
            copied += 1

        total_copied += copied
        stats[target_folder] = {"copied": copied, "skipped": skipped, "total_available": len(all_images)}
        print(f"  Copied: {copied}, Skipped (invalid): {skipped}")

    # Write updated labels.csv
    all_entries = existing + new_entries
    # Shuffle to mix old and new
    random.shuffle(all_entries)

    with open(LABELS_FILE, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["filename", "score"])
        for filename, score in all_entries:
            writer.writerow([filename, score])

    print(f"\n{'=' * 60}")
    print("INTEGRATION COMPLETE")
    print(f"{'=' * 60}")
    print(f"\n  Previously:  {len(existing)} images")
    print(f"  Added:       {total_copied} new images")
    print(f"  Total:       {len(all_entries)} images")
    print(f"\n  Per category:")
    for cat, s in stats.items():
        print(f"    {cat:15s}: +{s['copied']:4d}  (from {s['total_available']} available)")

    print(f"\n  Labels saved to: {LABELS_FILE}")
    print(f"  Original backup: {LABELS_BACKUP}")
    print(f"\n  Next step: Run train_dart_model.py and/or train_model.py to retrain!")


if __name__ == "__main__":
    main()
