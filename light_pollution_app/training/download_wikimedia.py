"""
Download REAL sky photos from Wikimedia Commons.
No API key needed — all images are real photographs, free, no watermarks.
"""

import os
import time
import json
import urllib.request
import urllib.parse
import hashlib
import numpy as np
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(SCRIPT_DIR, "dataset")

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}

# Wikimedia Commons API — search for real photographs by category
WIKI_API = "https://commons.wikimedia.org/w/api.php"

# Search queries mapped to Bortle categories
CATEGORIES = {
    "bortle_1_3": {
        "searches": [
            "Milky Way", "Milky Way photography", "Starry sky",
            "Dark sky", "Astrophotography night sky",
            "Night sky stars", "Milky Way landscape",
            "Star field photography", "Night sky desert",
            "Night sky mountains stars",
        ],
        "commons_cats": [
            "Milky_Way", "Astrophotography", "Night_sky",
            "Starry_skies", "Stars_in_the_sky",
        ],
    },
    "bortle_4_5": {
        "searches": [
            "Night sky village", "Rural night sky",
            "Night sky light pollution horizon",
            "Countryside night sky", "Stars over town",
            "Night sky farm", "Suburban stars night",
        ],
        "commons_cats": [
            "Night_sky_with_light_pollution",
            "Night_photographs_of_villages",
            "Night_skies_of_rural_areas",
        ],
    },
    "bortle_6_7": {
        "searches": [
            "Light pollution night sky", "Urban night sky",
            "Sky glow city", "Light pollution orange sky",
            "City sky glow night", "Urban sky night",
            "Light pollution photograph",
        ],
        "commons_cats": [
            "Light_pollution", "Skyglow",
            "Night_sky_with_light_pollution",
        ],
    },
    "bortle_8_9": {
        "searches": [
            "City night sky bright", "City skyline night",
            "Downtown night sky", "City lights night",
            "Bright city night sky", "Night sky metropolis",
            "Urban night bright sky",
        ],
        "commons_cats": [
            "Night_panoramas_of_cities",
            "Night_in_cities", "City_lights_at_night",
            "Nighttime_cityscapes",
        ],
    },
}

PER_SEARCH = 30  # Images per search query


def wikimedia_search_images(query, limit=30):
    """Search Wikimedia Commons for images matching a query."""
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": f"filetype:bitmap {query}",
        "gsrnamespace": "6",  # File namespace
        "gsrlimit": str(limit),
        "prop": "imageinfo",
        "iiprop": "url|size|mime",
        "iiurlwidth": "800",  # Get 800px thumbnail
    }

    url = WIKI_API + "?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "SuraTrainingBot/1.0 (sky quality research)"
        })
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())

        pages = data.get("query", {}).get("pages", {})
        results = []
        for page_id, page in pages.items():
            info = page.get("imageinfo", [{}])[0]
            thumb_url = info.get("thumburl")
            mime = info.get("mime", "")
            width = info.get("width", 0)
            height = info.get("height", 0)

            if thumb_url and "image" in mime and width >= 400 and height >= 300:
                results.append({
                    "url": thumb_url,
                    "title": page.get("title", ""),
                    "width": width,
                    "height": height,
                })

        return results
    except Exception as e:
        print(f"    Search error for '{query}': {e}")
        return []


def wikimedia_category_images(category, limit=30):
    """Get images from a Wikimedia Commons category."""
    params = {
        "action": "query",
        "format": "json",
        "generator": "categorymembers",
        "gcmtitle": f"Category:{category}",
        "gcmtype": "file",
        "gcmlimit": str(limit),
        "prop": "imageinfo",
        "iiprop": "url|size|mime",
        "iiurlwidth": "800",
    }

    url = WIKI_API + "?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "SuraTrainingBot/1.0 (sky quality research)"
        })
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())

        pages = data.get("query", {}).get("pages", {})
        results = []
        for page_id, page in pages.items():
            info = page.get("imageinfo", [{}])[0]
            thumb_url = info.get("thumburl")
            mime = info.get("mime", "")
            width = info.get("width", 0)
            height = info.get("height", 0)

            if thumb_url and "image" in mime and width >= 400 and height >= 300:
                results.append({
                    "url": thumb_url,
                    "title": page.get("title", ""),
                })

        return results
    except Exception as e:
        print(f"    Category error for '{category}': {e}")
        return []


def download_image(url, folder_path, index):
    """Download a single image."""
    ext = ".jpg"
    if ".png" in url.lower():
        ext = ".png"
    fname = f"wiki_{index:04d}{ext}"
    fpath = os.path.join(folder_path, fname)
    if os.path.exists(fpath):
        return False
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "SuraTrainingBot/1.0 (sky quality research)"
        })
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = resp.read()
        with open(fpath, "wb") as f:
            f.write(data)
        return True
    except Exception:
        return False


def is_valid_night_image(fpath):
    """Check if image is a real night sky photo."""
    try:
        img = Image.open(fpath).convert("RGB")
    except Exception:
        return False, "corrupt"

    w, h = img.size
    if w < 200 or h < 150:
        return False, "too small"

    arr = np.array(img.resize((224, 224)), dtype=np.float32) / 255.0
    mean_brightness = arr.mean()

    if mean_brightness > 0.95:
        return False, "blank/white"
    if mean_brightness > 0.75:
        return False, "too bright (daytime)"

    max_ch = np.maximum(np.maximum(arr[:,:,0], arr[:,:,1]), arr[:,:,2])
    min_ch = np.minimum(np.minimum(arr[:,:,0], arr[:,:,1]), arr[:,:,2])
    sat = np.where(max_ch > 0.01, (max_ch - min_ch) / max_ch, 0)
    mean_sat = float(np.nanmean(sat))

    if mean_sat > 0.65 and mean_brightness > 0.4:
        return False, "likely illustration"

    return True, "ok"


def deduplicate_folder(folder_path):
    """Remove duplicate images."""
    seen = set()
    removed = 0
    for fname in sorted(os.listdir(folder_path)):
        if os.path.splitext(fname)[1].lower() not in IMAGE_EXTENSIONS:
            continue
        fpath = os.path.join(folder_path, fname)
        try:
            img = Image.open(fpath).convert("L").resize((16, 16))
            arr = np.array(img)
            bits = (arr > arr.mean()).flatten()
            h = hashlib.md5(bits.tobytes()).hexdigest()[:16]
            if h in seen:
                os.remove(fpath)
                removed += 1
            else:
                seen.add(h)
        except Exception:
            os.remove(fpath)
            removed += 1
    return removed


def count_images(folder_path):
    if not os.path.isdir(folder_path):
        return 0
    return len([f for f in os.listdir(folder_path)
                if os.path.splitext(f)[1].lower() in IMAGE_EXTENSIONS])


def main():
    print("=" * 60)
    print("  SURA Dataset — Wikimedia Commons Downloader")
    print("  Real photos, no watermarks, no API key needed")
    print("=" * 60)

    for folder_name, config in CATEGORIES.items():
        folder_path = os.path.join(DATASET_DIR, folder_name)
        os.makedirs(folder_path, exist_ok=True)

        existing = count_images(folder_path)
        print(f"\n{'='*50}")
        print(f"  {folder_name}  (existing: {existing})")
        print(f"{'='*50}")

        all_urls = []
        seen_urls = set()

        # Search-based queries
        for query in config["searches"]:
            print(f"  Searching: \"{query}\"")
            results = wikimedia_search_images(query, limit=PER_SEARCH)
            for r in results:
                if r["url"] not in seen_urls:
                    all_urls.append(r["url"])
                    seen_urls.add(r["url"])
            time.sleep(0.5)

        # Category-based queries
        for cat in config["commons_cats"]:
            print(f"  Category: {cat}")
            results = wikimedia_category_images(cat, limit=PER_SEARCH)
            for r in results:
                if r["url"] not in seen_urls:
                    all_urls.append(r["url"])
                    seen_urls.add(r["url"])
            time.sleep(0.5)

        print(f"  Found {len(all_urls)} unique image URLs")

        # Download
        downloaded = 0
        idx = existing
        for url in all_urls:
            if download_image(url, folder_path, idx):
                downloaded += 1
                idx += 1
            if downloaded % 20 == 0 and downloaded > 0:
                print(f"    ...downloaded {downloaded}")

        print(f"  Downloaded: {downloaded}")

        # Cleanup
        removed = 0
        for fname in sorted(os.listdir(folder_path)):
            if os.path.splitext(fname)[1].lower() not in IMAGE_EXTENSIONS:
                continue
            fpath = os.path.join(folder_path, fname)
            valid, reason = is_valid_night_image(fpath)
            if not valid:
                os.remove(fpath)
                removed += 1
                print(f"    Removed {fname}: {reason}")

        dupes = deduplicate_folder(folder_path)
        final = count_images(folder_path)
        print(f"  Cleaned: -{removed} bad, -{dupes} dupes → {final} final")

    # Summary
    print("\n" + "=" * 60)
    print("  Download complete!")
    print("=" * 60)
    total = 0
    for folder_name in CATEGORIES:
        c = count_images(os.path.join(DATASET_DIR, folder_name))
        total += c
        print(f"  {folder_name}: {c} images")
    print(f"\n  Total: {total} real sky images")
    print("\nNext step: python train_model.py")


if __name__ == "__main__":
    main()
