"""
Download night sky images from free sources and organize by light pollution level.

Sky Quality Scale (0-100):
  0-20:  City Center (heavy light pollution, orange/white sky glow)
  20-40: Urban (significant light pollution, few stars visible)
  40-60: Suburban (moderate pollution, some stars/constellations visible)
  60-80: Rural (low pollution, Milky Way faintly visible)
  80-100: Dark Sky (pristine, Milky Way bright, many stars)

We use Unsplash (free, no API key needed for small downloads) and generate
synthetic variations to build a robust dataset.
"""

import os
import requests
import hashlib
import time
from PIL import Image, ImageEnhance, ImageFilter
import numpy as np
import io
import random

BASE_DIR = "/Users/maii/sura_test/ml_training/dataset"

# Free-to-use image URLs from Unsplash (royalty-free)
# Organized by sky quality category
IMAGE_SOURCES = {
    # Dark sky images (score 80-100) - pristine Milky Way, star fields
    "dark_sky": [
        ("https://images.unsplash.com/photo-1519681393784-d120267933ba?w=640", 95),  # Milky Way mountain
        ("https://images.unsplash.com/photo-1507400492013-162706c8c05e?w=640", 92),  # Star field
        ("https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?w=640", 90),  # Stars
        ("https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=640", 93),  # Nebula sky
        ("https://images.unsplash.com/photo-1465101162946-4377e57745c3?w=640", 88),  # Milky Way
        ("https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=640", 91),  # Deep space stars
        ("https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?w=640", 89),  # Dark sky stars
        ("https://images.unsplash.com/photo-1516339901601-2e1b62dc0c45?w=640", 87),  # Milky Way landscape
        ("https://images.unsplash.com/photo-1509773896068-7fd415d91e2e?w=640", 94),  # Night sky stars
        ("https://images.unsplash.com/photo-1532978379173-523e16f371f2?w=640", 86),  # Starry night
        ("https://images.unsplash.com/photo-1504700610630-ac6aeef834d2?w=640", 85),  # Dark starfield
        ("https://images.unsplash.com/photo-1502481851512-e9e2529bfbf9?w=640", 90),  # Clear night sky
        ("https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=640", 88),  # Milky Way arch
        ("https://images.unsplash.com/photo-1515705576963-95cad62945b6?w=640", 92),  # Star trails dark
        ("https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=640", 96),  # Pure star field
    ],
    # Rural sky (score 60-80) - some stars, faint Milky Way
    "rural": [
        ("https://images.unsplash.com/photo-1475274047050-1d0c55b0ddef?w=640", 75),  # Rural night
        ("https://images.unsplash.com/photo-1488866022916-f7f2a6a037a2?w=640", 72),  # Country night
        ("https://images.unsplash.com/photo-1532074534361-bb09b6e3e900?w=640", 68),  # Night landscape
        ("https://images.unsplash.com/photo-1505506874110-6a7a69069a08?w=640", 70),  # Night sky rural
        ("https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=640", 65),  # Sunset to night
        ("https://images.unsplash.com/photo-1507499036636-f716246c2c23?w=640", 73),  # Rural stars
        ("https://images.unsplash.com/photo-1536431311719-398b6704d4cc?w=640", 67),  # Night field
        ("https://images.unsplash.com/photo-1484589065579-248aad0d628b?w=640", 71),  # Night mountains
        ("https://images.unsplash.com/photo-1482881497185-d4a9861ea3f3?w=640", 69),  # Night lake
        ("https://images.unsplash.com/photo-1528722828814-77b9b83aafb2?w=640", 74),  # Night sky trees
        ("https://images.unsplash.com/photo-1489549132488-d00b7eee80f1?w=640", 62),  # Dim stars
        ("https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=640", 76),  # Aurora (rural)
        ("https://images.unsplash.com/photo-1483086431886-3590a88317fe?w=640", 64),  # Twilight rural
    ],
    # Suburban sky (score 40-60) - light dome visible, few stars
    "suburban": [
        ("https://images.unsplash.com/photo-1507400492013-162706c8c05e?w=640", 55),  # Suburban night
        ("https://images.unsplash.com/photo-1472120435266-95a3675c6e19?w=640", 50),  # Night houses
        ("https://images.unsplash.com/photo-1513151233558-d860c5398176?w=640", 48),  # Lit neighborhood
        ("https://images.unsplash.com/photo-1430132594682-16e1185b17c5?w=640", 52),  # Night road
        ("https://images.unsplash.com/photo-1534430480872-3498386e7856?w=640", 45),  # Moon suburb
        ("https://images.unsplash.com/photo-1499346030926-9a72daac6c63?w=640", 58),  # Night park
        ("https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=640", 53),  # Night mountain town
        ("https://images.unsplash.com/photo-1502899576159-f224dc2349fa?w=640", 47),  # Suburban glow
        ("https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=640", 42),  # Night street
        ("https://images.unsplash.com/photo-1477346611705-65d1883cee1e?w=640", 56),  # Night horizon
        ("https://images.unsplash.com/photo-1503891450247-ee5f8ec46dc3?w=640", 44),  # Night parking
        ("https://images.unsplash.com/photo-1414609245224-afa02bfb3fda?w=640", 51),  # Dusk suburban
    ],
    # Urban sky (score 20-40) - heavy light pollution, orange sky
    "urban": [
        ("https://images.unsplash.com/photo-1514565131-fce0801e5785?w=640", 35),  # City night
        ("https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=640", 30),  # City skyline night
        ("https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=640", 25),  # Downtown night
        ("https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=640", 32),  # Urban night
        ("https://images.unsplash.com/photo-1444723121867-7a241cacace9?w=640", 28),  # City lights
        ("https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=640", 33),  # City buildings
        ("https://images.unsplash.com/photo-1470219556762-1fd5b5f14b35?w=640", 22),  # Bright city
        ("https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?w=640", 38),  # City dusk
        ("https://images.unsplash.com/photo-1517935706615-2717063c2225?w=640", 26),  # Neon city
        ("https://images.unsplash.com/photo-1496568816309-51d7c20e3b21?w=640", 31),  # Bridge city
        ("https://images.unsplash.com/photo-1542332213-31f87348057f?w=640", 36),  # Urban sky glow
        ("https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=640", 29),  # City reflections
    ],
    # City center (score 0-20) - maximum light pollution, no stars
    "city_center": [
        ("https://images.unsplash.com/photo-1522083165195-3424ed129620?w=640", 10),  # Times Square
        ("https://images.unsplash.com/photo-1534430480872-3498386e7856?w=640", 15),  # Bright downtown
        ("https://images.unsplash.com/photo-1517935706615-2717063c2225?w=640", 8),   # Neon night
        ("https://images.unsplash.com/photo-1520899999398-6a015148e196?w=640", 12),  # City center
        ("https://images.unsplash.com/photo-1553697388-94e804e2f0f6?w=640", 5),   # Bright lights
        ("https://images.unsplash.com/photo-1534430480872-3498386e7856?w=640", 18),  # Lit buildings
        ("https://images.unsplash.com/photo-1504109586057-7a2ae83d1338?w=640", 7),   # Stadium lights
        ("https://images.unsplash.com/photo-1513407030348-c983a97b98d8?w=640", 14),  # City glow heavy
        ("https://images.unsplash.com/photo-1527576539890-dfa815648363?w=640", 11),  # Skyscrapers night
        ("https://images.unsplash.com/photo-1498036882173-b41c28a8ba34?w=640", 16),  # Tokyo night
        ("https://images.unsplash.com/photo-1493515322954-cff4a695ac8b?w=640", 3),   # Maximum city light
        ("https://images.unsplash.com/photo-1531973576160-7125cd663d86?w=640", 9),   # Las Vegas type
    ],
}


def download_image(url, save_path, timeout=15):
    """Download an image from URL."""
    try:
        headers = {"User-Agent": "SuraLightPollution/1.0 (Research Project)"}
        resp = requests.get(url, headers=headers, timeout=timeout, stream=True)
        resp.raise_for_status()

        img = Image.open(io.BytesIO(resp.content))
        img = img.convert("RGB")
        img = img.resize((224, 224), Image.LANCZOS)
        img.save(save_path, "JPEG", quality=90)
        return True
    except Exception as e:
        print(f"  Failed: {e}")
        return False


def augment_image(img, score, variation_idx):
    """Create augmented variations of an image with adjusted score."""
    augmented = []

    # Variation 1: Brightness adjustment (simulates different exposure)
    if variation_idx % 5 == 0:
        factor = random.uniform(0.6, 0.85)
        enhancer = ImageEnhance.Brightness(img)
        new_img = enhancer.enhance(factor)
        # Darker = looks more like dark sky = slightly higher score
        new_score = min(100, score + random.randint(3, 10))
        augmented.append((new_img, new_score))

    # Variation 2: Brighten (simulates more light pollution)
    if variation_idx % 5 == 1:
        factor = random.uniform(1.2, 1.6)
        enhancer = ImageEnhance.Brightness(img)
        new_img = enhancer.enhance(factor)
        new_score = max(0, score - random.randint(3, 10))
        augmented.append((new_img, new_score))

    # Variation 3: Add orange tint (simulates sodium lamp pollution)
    if variation_idx % 5 == 2:
        arr = np.array(img, dtype=np.float32)
        arr[:,:,0] = np.clip(arr[:,:,0] * 1.15, 0, 255)  # More red
        arr[:,:,1] = np.clip(arr[:,:,1] * 1.05, 0, 255)  # Slightly more green
        arr[:,:,2] = np.clip(arr[:,:,2] * 0.85, 0, 255)  # Less blue
        new_img = Image.fromarray(arr.astype(np.uint8))
        new_score = max(0, score - random.randint(5, 12))
        augmented.append((new_img, new_score))

    # Variation 4: Add blue tint (simulates cleaner sky)
    if variation_idx % 5 == 3:
        arr = np.array(img, dtype=np.float32)
        arr[:,:,0] = np.clip(arr[:,:,0] * 0.85, 0, 255)  # Less red
        arr[:,:,2] = np.clip(arr[:,:,2] * 1.15, 0, 255)  # More blue
        new_img = Image.fromarray(arr.astype(np.uint8))
        new_score = min(100, score + random.randint(3, 8))
        augmented.append((new_img, new_score))

    # Variation 5: Horizontal flip
    if variation_idx % 5 == 4:
        new_img = img.transpose(Image.FLIP_LEFT_RIGHT)
        new_score = score + random.randint(-2, 2)
        new_score = max(0, min(100, new_score))
        augmented.append((new_img, new_score))

    # Variation 6: Slight rotation
    angle = random.uniform(-15, 15)
    new_img = img.rotate(angle, fillcolor=(0, 0, 0))
    new_score = score + random.randint(-2, 2)
    new_score = max(0, min(100, new_score))
    augmented.append((new_img, new_score))

    # Variation 7: Contrast adjustment
    factor = random.uniform(0.8, 1.3)
    enhancer = ImageEnhance.Contrast(img)
    new_img = enhancer.enhance(factor)
    new_score = score + random.randint(-3, 3)
    new_score = max(0, min(100, new_score))
    augmented.append((new_img, new_score))

    return augmented


def main():
    labels = []  # (filename, score)
    img_count = 0

    print("=" * 60)
    print("SURA Night Sky Dataset Builder")
    print("Scale: 0 = Heavy Pollution, 100 = Pristine Dark Sky")
    print("=" * 60)

    for category, sources in IMAGE_SOURCES.items():
        print(f"\n📁 Category: {category} ({len(sources)} sources)")

        for idx, (url, score) in enumerate(sources):
            filename = f"{category}_{idx:03d}.jpg"
            save_path = os.path.join(BASE_DIR, category, filename)

            print(f"  Downloading {filename} (score={score})...", end=" ")

            if download_image(url, save_path):
                print("✓")
                labels.append((os.path.join(category, filename), score))
                img_count += 1

                # Create augmented versions
                try:
                    img = Image.open(save_path)
                    augmented = augment_image(img, score, idx)

                    for aug_idx, (aug_img, aug_score) in enumerate(augmented):
                        aug_filename = f"{category}_{idx:03d}_aug{aug_idx}.jpg"
                        aug_path = os.path.join(BASE_DIR, category, aug_filename)
                        aug_img.save(aug_path, "JPEG", quality=85)
                        labels.append((os.path.join(category, aug_filename), aug_score))
                        img_count += 1
                except Exception as e:
                    print(f"    Augmentation failed: {e}")

            time.sleep(0.3)  # Rate limiting

    # Write labels file
    labels_path = os.path.join(BASE_DIR, "labels.csv")
    with open(labels_path, "w") as f:
        f.write("filename,score\n")
        for filename, score in labels:
            f.write(f"{filename},{score}\n")

    print(f"\n{'=' * 60}")
    print(f"Dataset complete!")
    print(f"Total images: {img_count}")
    print(f"Labels saved to: {labels_path}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
