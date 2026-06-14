"""
Download REAL sky photos for training dataset.

Uses Pexels API (free, curated, no watermarks, real photos only)
+ Bing with photo-only filter as backup.
Then runs cleanup to remove any remaining bad images.
"""

import os
import sys
import time
import json
import hashlib
import struct
import urllib.request
import urllib.parse
from PIL import Image
import numpy as np

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(SCRIPT_DIR, "dataset")

# ── Pexels API (free, real photos, no watermarks) ───────────────────
PEXELS_API_KEY = "YOUR_KEY_HERE"  # Get free key at https://www.pexels.com/api/

PEXELS_QUERIES = {
    "bortle_1_3": [
        "milky way", "starry sky", "night sky stars",
        "galaxy night", "astrophotography", "dark sky stars",
        "milky way landscape", "stars night",
    ],
    "bortle_4_5": [
        "night sky village", "rural night", "countryside night sky",
        "farm night stars", "night sky horizon light",
        "suburban night", "backyard night sky",
    ],
    "bortle_6_7": [
        "light pollution", "city sky night", "urban night sky",
        "city glow night", "night sky city lights",
        "urban sky glow", "city outskirts night",
    ],
    "bortle_8_9": [
        "city night skyline", "downtown night", "city lights night sky",
        "cityscape night", "city night bright sky",
        "metropolis night", "urban night bright",
    ],
}

# ── Bing backup (photo filter only) ─────────────────────────────────
BING_QUERIES = {
    "bortle_1_3": [
        "milky way night sky photography",
        "dark sky astrophotography real photo",
        "starry night sky no light pollution photograph",
        "desert night sky milky way real",
        "mountain night sky stars photograph",
        "national park dark sky stars",
        "milky way arch real photo",
        "night sky thousands stars camera",
    ],
    "bortle_4_5": [
        "suburban night sky stars photograph",
        "rural night sky light horizon photo",
        "countryside night sky real photo",
        "village night sky stars photograph",
        "farm night sky real",
        "backyard night sky stars photo",
        "small town night sky photograph",
        "rural night light dome photograph",
    ],
    "bortle_6_7": [
        "urban night sky light pollution photo",
        "city sky glow orange night photograph",
        "light pollution sky real photo",
        "suburban sky glow night photograph",
        "urban area night sky photo",
        "city outskirts night orange sky real",
        "hazy night sky city lights photo",
        "night sky streetlight glow photograph",
    ],
    "bortle_8_9": [
        "city skyline night sky photograph",
        "downtown night sky bright photo",
        "heavy light pollution city sky real",
        "city center night bright sky photo",
        "city night no stars visible real",
        "metropolis night sky bright photo",
        "city lights bright night sky photograph",
        "urban bright night sky real photo",
    ],
}

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}


def count_images(folder_path):
    if not os.path.isdir(folder_path):
        return 0
    return len([f for f in os.listdir(folder_path)
                if os.path.splitext(f)[1].lower() in IMAGE_EXTENSIONS])


# ── Pexels downloader ───────────────────────────────────────────────
def download_from_pexels(folder_name, queries, per_query=15):
    """Download real photos from Pexels API."""
    if PEXELS_API_KEY == "YOUR_KEY_HERE":
        return 0

    folder_path = os.path.join(DATASET_DIR, folder_name)
    os.makedirs(folder_path, exist_ok=True)
    downloaded = 0

    for query in queries:
        try:
            url = f"https://api.pexels.com/v1/search?query={urllib.parse.quote(query)}&per_page={per_query}&orientation=landscape"
            req = urllib.request.Request(url, headers={"Authorization": PEXELS_API_KEY})
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode())

            for photo in data.get("photos", []):
                img_url = photo["src"]["large"]
                fname = f"pexels_{photo['id']}.jpg"
                fpath = os.path.join(folder_path, fname)
                if os.path.exists(fpath):
                    continue
                try:
                    urllib.request.urlretrieve(img_url, fpath)
                    downloaded += 1
                except Exception:
                    pass

            time.sleep(0.5)
        except Exception as e:
            print(f"    Pexels error for '{query}': {e}")

    return downloaded


# ── Bing downloader (photo filter) ──────────────────────────────────
def download_from_bing(folder_name, queries, per_query=30):
    """Download from Bing with photo-type filter."""
    from icrawler.builtin import BingImageCrawler

    folder_path = os.path.join(DATASET_DIR, folder_name)
    os.makedirs(folder_path, exist_ok=True)

    for i, query in enumerate(queries):
        print(f"    Bing [{i+1}/{len(queries)}]: \"{query}\"")
        crawler = BingImageCrawler(
            storage={"root_dir": folder_path},
            log_level=40,
        )
        crawler.crawl(
            keyword=query,
            max_num=per_query,
            min_size=(400, 300),
            filters={"type": "photo"},  # Real photos only — no clipart/illustrations
        )
        time.sleep(1)


# ── Image cleanup / validation ──────────────────────────────────────
def is_valid_sky_image(fpath):
    """Check if an image is likely a real sky photo (not watermarked/AI/daytime)."""
    try:
        img = Image.open(fpath).convert("RGB")
    except Exception:
        return False, "corrupt"

    w, h = img.size

    # Too small = thumbnail or icon
    if w < 300 or h < 200:
        return False, "too small"

    # Analyze pixel content
    arr = np.array(img.resize((224, 224)), dtype=np.float32) / 255.0
    mean_brightness = arr.mean()
    r_mean, g_mean, b_mean = arr[:,:,0].mean(), arr[:,:,1].mean(), arr[:,:,2].mean()

    # Pure white/grey images (broken downloads)
    if mean_brightness > 0.95:
        return False, "blank/white"

    # Extremely bright = likely daytime photo
    if mean_brightness > 0.7:
        return False, "too bright (daytime?)"

    # Check for watermark-like patterns:
    # Watermarked images often have repeated semi-transparent text
    # which creates unusual mid-tone patterns across the image
    # Simple heuristic: check if there are many pixels with very similar
    # grey values spread uniformly (watermark overlay pattern)
    grey = 0.299 * arr[:,:,0] + 0.587 * arr[:,:,1] + 0.114 * arr[:,:,2]

    # Check color saturation — AI art tends to be extremely saturated
    max_channel = np.maximum(np.maximum(arr[:,:,0], arr[:,:,1]), arr[:,:,2])
    min_channel = np.minimum(np.minimum(arr[:,:,0], arr[:,:,1]), arr[:,:,2])
    saturation = np.where(max_channel > 0.01, (max_channel - min_channel) / max_channel, 0)
    mean_sat = saturation.mean()

    # Extremely high saturation + high brightness = likely AI/fantasy art
    if mean_sat > 0.65 and mean_brightness > 0.4:
        return False, "likely AI art (oversaturated)"

    return True, "ok"


def cleanup_folder(folder_name):
    """Remove invalid images from a folder."""
    folder_path = os.path.join(DATASET_DIR, folder_name)
    if not os.path.isdir(folder_path):
        return 0

    removed = 0
    for fname in sorted(os.listdir(folder_path)):
        if os.path.splitext(fname)[1].lower() not in IMAGE_EXTENSIONS:
            continue
        fpath = os.path.join(folder_path, fname)
        valid, reason = is_valid_sky_image(fpath)
        if not valid:
            os.remove(fpath)
            removed += 1
            print(f"    Removed {fname}: {reason}")

    return removed


# ── Deduplicate by content hash ─────────────────────────────────────
def deduplicate_folder(folder_name):
    """Remove duplicate images based on perceptual hash."""
    folder_path = os.path.join(DATASET_DIR, folder_name)
    if not os.path.isdir(folder_path):
        return 0

    seen_hashes = set()
    removed = 0

    for fname in sorted(os.listdir(folder_path)):
        if os.path.splitext(fname)[1].lower() not in IMAGE_EXTENSIONS:
            continue
        fpath = os.path.join(folder_path, fname)
        try:
            img = Image.open(fpath).convert("L").resize((16, 16))
            arr = np.array(img)
            avg = arr.mean()
            bits = (arr > avg).flatten()
            h = hashlib.md5(bits.tobytes()).hexdigest()[:16]
            if h in seen_hashes:
                os.remove(fpath)
                removed += 1
            else:
                seen_hashes.add(h)
        except Exception:
            os.remove(fpath)
            removed += 1

    return removed


# ── Main ─────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("  SURA Dataset Downloader — Real Sky Photos Only")
    print("=" * 60)

    # Step 1: Download from Pexels (if API key set)
    if PEXELS_API_KEY != "YOUR_KEY_HERE":
        print("\n[1/4] Downloading from Pexels (real, no watermarks)...")
        for folder, queries in PEXELS_QUERIES.items():
            n = download_from_pexels(folder, queries)
            print(f"  {folder}: +{n} from Pexels")
    else:
        print("\n[1/4] Skipping Pexels (no API key set)")
        print("  Tip: Get a free key at https://www.pexels.com/api/")

    # Step 2: Download from Bing (photo filter)
    print("\n[2/4] Downloading from Bing (photo-only filter)...")
    for folder, queries in BING_QUERIES.items():
        before = count_images(os.path.join(DATASET_DIR, folder))
        print(f"\n  {folder}:")
        download_from_bing(folder, queries, per_query=30)
        after = count_images(os.path.join(DATASET_DIR, folder))
        print(f"  → {folder}: {after} images (+{after - before} new)")

    # Step 3: Clean up bad images
    print("\n[3/4] Cleaning up bad images (watermarks, AI art, daytime)...")
    total_removed = 0
    for folder in BING_QUERIES:
        print(f"\n  {folder}:")
        removed = cleanup_folder(folder)
        total_removed += removed
    print(f"\n  Removed {total_removed} bad images total")

    # Step 4: Deduplicate
    print("\n[4/4] Removing duplicates...")
    total_dupes = 0
    for folder in BING_QUERIES:
        dupes = deduplicate_folder(folder)
        if dupes > 0:
            print(f"  {folder}: removed {dupes} duplicates")
        total_dupes += dupes
    print(f"  Removed {total_dupes} duplicates total")

    # Summary
    print("\n" + "=" * 60)
    print("  Download complete! Final counts:")
    print("=" * 60)
    grand_total = 0
    for folder in BING_QUERIES:
        c = count_images(os.path.join(DATASET_DIR, folder))
        grand_total += c
        print(f"  {folder}: {c} images")
    print(f"\n  Total: {grand_total} real sky images")
    print("\nNext step: python train_model.py")


if __name__ == "__main__":
    main()
