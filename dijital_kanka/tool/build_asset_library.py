"""Zibo'nun Evi eşya kütüphanesi: ham CC0/MIT paketlerden `asset_library/` üretir.

Her eşya aynı stil hattından geçer: 3B model render + kalın kontur + sert gölge, WebP.
Ham paketler repoda yok (büyük); nasıl indirileceği `asset_library/README.md`'de.

Kullanım: python tool/build_asset_library.py <ham_klasör> <asset_library_klasörü>
"""
import glob
import io
import json
import multiprocessing
import os
import re
import sys
import zipfile

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

INK = (20, 17, 12)
LONG_SIDE = 256
MAX_TRIANGLES = 40000
KENNEY_YAW = 148
QUATERNIUS_YAW = -32
QUATERNIUS_LIFT = 1.32


# Kenney Nature Kit yeşilleri turkuaz tanımlı; Zibo'nun odalarında bitki yeşil görünsün.
MATERIAL_OVERRIDES = {"leafsGreen": [0.30, 0.68, 0.28], "leafsDark": [0.18, 0.50, 0.26], "grass": [0.36, 0.74, 0.30]}


def load_obj(obj_text, mtl_text, texture=None):
    """`texture` (PIL RGB): Kd'si beyaz, rengi `map_Kd`'den gelen paketler (Kenney Holiday Kit)."""
    kd = {}
    cur = None
    for line in mtl_text.splitlines():
        p = line.split()
        if not p:
            continue
        if p[0] == "newmtl":
            cur = p[1]
        elif p[0] == "Kd" and cur:
            kd[cur] = MATERIAL_OVERRIDES.get(cur, [float(x) for x in p[1:4]])
    V, T, F, C = [], [], [], []
    col = [0.8, 0.8, 0.8]
    for line in obj_text.splitlines():
        p = line.split()
        if not p:
            continue
        if p[0] == "v":
            V.append([float(x) for x in p[1:4]])
        elif p[0] == "vt":
            T.append([float(x) for x in p[1:3]])
        elif p[0] == "usemtl":
            col = kd.get(p[1], [0.8, 0.8, 0.8])
        elif p[0] == "f":
            parts = [t.split("/") for t in p[1:]]
            idx = [int(t[0]) for t in parts]
            idx = [i - 1 if i > 0 else len(V) + i for i in idx]
            face_col = col
            if texture is not None and len(parts[0]) > 1 and parts[0][1]:
                uvs = np.array([T[int(t[1]) - 1] for t in parts], float).mean(0)
                x = min(int(uvs[0] % 1 * texture.width), texture.width - 1)
                y = min(int((1 - uvs[1] % 1) * texture.height), texture.height - 1)
                # Doku sRGB; render'daki gama adımı renkleri soldurmasın diye doğrusala çevrilir.
                face_col = [(v / 255) ** 2.2 for v in texture.getpixel((x, y))[:3]]
            for k in range(1, len(idx) - 1):
                F.append([idx[0], idx[k], idx[k + 1]])
                C.append(face_col)
    return np.array(V, float), np.array(F, int), np.array(C, float)


def render(V, F, C, size, yaw, pitch, lift, ss=2):
    y, p = np.radians(yaw), np.radians(pitch)
    Ry = np.array([[np.cos(y), 0, np.sin(y)], [0, 1, 0], [-np.sin(y), 0, np.cos(y)]])
    Rx = np.array([[1, 0, 0], [0, np.cos(p), -np.sin(p)], [0, np.sin(p), np.cos(p)]])
    W = (V - V.mean(0)) @ Ry.T @ Rx.T
    mn, mx = W[:, :2].min(0), W[:, :2].max(0)
    N = size * ss
    pad = 0.03 * N
    s = (N - 2 * pad) / (mx - mn).max()
    px = (W[:, 0] - (mn[0] + mx[0]) / 2) * s + N / 2
    py = N / 2 - (W[:, 1] - (mn[1] + mx[1]) / 2) * s
    pz = W[:, 2] * s
    zb = np.full((N, N), -1e18)
    img = np.zeros((N, N, 3))
    a = np.zeros((N, N), bool)
    L = np.array([-0.45, 0.75, 0.55])
    L /= np.linalg.norm(L)
    for (i, j, k), c in zip(F, C):
        n = np.cross(W[j] - W[i], W[k] - W[i])
        ln = np.linalg.norm(n)
        if ln < 1e-12:
            continue
        n /= ln
        x0, y0, x1, y1, x2, y2 = px[i], py[i], px[j], py[j], px[k], py[k]
        d = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
        if abs(d) < 1e-9:
            continue
        if n[2] < 0:
            n = -n
        xa, xb = max(int(min(x0, x1, x2)), 0), min(int(max(x0, x1, x2)) + 1, N - 1)
        ya, yb = max(int(min(y0, y1, y2)), 0), min(int(max(y0, y1, y2)) + 1, N - 1)
        if xa > xb or ya > yb:
            continue
        X, Y = np.meshgrid(np.arange(xa, xb + 1) + 0.5, np.arange(ya, yb + 1) + 0.5)
        l0 = ((y1 - y2) * (X - x2) + (x2 - x1) * (Y - y2)) / d
        l1 = ((y2 - y0) * (X - x2) + (x0 - x2) * (Y - y2)) / d
        m = (l0 >= 0) & (l1 >= 0) & (l0 + l1 <= 1)
        if not m.any():
            continue
        z = l0 * pz[i] + l1 * pz[j] + (1 - l0 - l1) * pz[k]
        sub = zb[ya : yb + 1, xa : xb + 1]
        m &= z > sub
        if not m.any():
            continue
        sub[m] = z[m]
        dif = max(0.0, float(n @ L))
        shade = 1.04 if dif > 0.62 else (0.86 if dif > 0.26 else 0.68)
        img[ya : yb + 1, xa : xb + 1][m] = np.clip(np.power(np.array(c), 1 / 2.2) * shade * lift, 0, 1)
        a[ya : yb + 1, xa : xb + 1][m] = True
    rgba = np.dstack([(img * 255).astype("uint8"), (a * 255).astype("uint8")])
    return Image.fromarray(rgba, "RGBA").resize((size, size), Image.LANCZOS)


def fit(im, long):
    im = im.crop(im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox())
    r = long / max(im.size)
    return im.resize((max(1, round(im.width * r)), max(1, round(im.height * r))), Image.LANCZOS)


def sticker(im, long):
    im = fit(im, long)
    w = max(4, round(long * 0.018))
    pad = w + 6
    c = Image.new("RGBA", (im.width + pad * 2 + w, im.height + pad * 2 + w), (0, 0, 0, 0))
    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(1.12).convert("RGBA")
    rgb.putalpha(im.getchannel("A"))
    al = Image.new("L", c.size, 0)
    al.paste(im.getchannel("A"), (pad, pad))
    big = al.filter(ImageFilter.MaxFilter(2 * w + 1)).filter(ImageFilter.GaussianBlur(0.7))
    ink = Image.new("RGBA", c.size, INK + (0,))
    ink.putalpha(big)
    sh = Image.new("RGBA", c.size, INK + (0,))
    sa = Image.new("L", c.size, 0)
    sa.paste(big, (round(w * 0.7), round(w * 0.7)))
    sh.putalpha(sa)
    c.alpha_composite(sh)
    c.alpha_composite(ink)
    c.alpha_composite(rgb, (pad, pad))
    return c


def title(name):
    name = re.sub(r"[_\-]+", " ", name)
    name = re.sub(r"(?<=[a-z])(?=[A-Z0-9])", " ", name)
    return name.strip().capitalize()


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", re.sub(r"(?<=[a-z])(?=[A-Z])", "_", name).lower()).strip("_")


def kenney_room(n):
    low = n.lower()
    if re.search(r"^(wall|floor|doorway|paneling)", low):
        return None
    if re.search(r"bath|shower|toilet|washer|dryer", low):
        return "banyo"
    if re.search(r"kitchen|stool|trashcan", low):
        return "mutfak"
    if re.search(r"^bed|cabinetbed|pillow|coatrack", low):
        return "yatak"
    if re.search(r"plant", low):
        return "bahce"
    return "salon"


def house_room(n):
    head = n.split("_")[0]
    if head in ("Door", "Window", "Column", "Wall", "Floor", "Stair", "Stairs"):
        return None
    if head in ("Bathroom", "Trashcan"):
        return "banyo"
    if head in ("Kitchen", "Plate", "Fork", "Knife", "Spoon", "Cup", "Glass"):
        return "mutfak"
    if head in ("Bed", "NightStand", "Drawer", "Curtains"):
        return "yatak"
    if head == "Houseplant":
        return "bahce"
    return "salon"


def nature_room(n):
    return "bahce" if re.match(r"(tree|flower|plant|mushroom|cactus|pot|fence|stump|lily|grass|statue|hanging)", n) else None


def holiday_room(n):
    return None if re.match(r"(cabin|floor|snow-|rocks)", n) else "sezonluk"


def crops_room(n):
    # Paket bitki büyüme evreleri içeriyor, yemek değil: bahçe eşyası sayılır.
    return "bahce" if "Harvested" in n or re.match(r"(Apple|Banana|Orange|Pumpkin|Carrot|Corn|Tomato)_\d?$", n) else None


PACKS = [
    ("kenney_furniture", "kenney/pack.zip", "Kenney Furniture Pack", "CC0", KENNEY_YAW, 1.0, kenney_room),
    ("kenney_holiday", "oga/holiday-kit/pack.zip", "Kenney Holiday Kit", "CC0", KENNEY_YAW, 1.0, holiday_room),
    ("kenney_nature", "oga/nature-kit/pack.zip", "Kenney Nature Kit", "CC0", KENNEY_YAW, 1.0, nature_room),
    ("quat_house", "oga/lowpoly-house-interior-pack/pack.zip", "Quaternius House Interior", "CC0", QUATERNIUS_YAW, QUATERNIUS_LIFT, house_room),
    ("quat_furn1", "oga/furniture-low-poly/pack.zip", "Quaternius Furniture Pack", "CC0", QUATERNIUS_YAW, QUATERNIUS_LIFT, lambda n: "yatak" if n.startswith("Bed") else "salon"),
    ("quat_furn2", "oga/low-poly-furniture-1/pack.zip", "Quaternius Furniture Vol.2", "CC0", QUATERNIUS_YAW, QUATERNIUS_LIFT, lambda n: "salon"),
    ("quat_food", "quat/pack.zip", "Quaternius Ultimate Food", "CC0", -28, QUATERNIUS_LIFT, lambda n: "yemek"),
    ("quat_crops", "oga/lowpoly-crops-pack/pack.zip", "Quaternius Crops", "CC0", -28, QUATERNIUS_LIFT, crops_room),
]
FLUENT_GROUPS = {"Food & Drink": "yemek", "Objects": "esya", "Animals & Nature": "doga", "Activities": "oyun"}


def model_jobs(raw):
    jobs = []
    for key, path, source, lic, yaw, lift, room in PACKS:
        z = zipfile.ZipFile(os.path.join(raw, path))
        seen = set()
        for n in z.namelist():
            if not n.lower().endswith(".obj") or "__MACOSX" in n:
                continue
            base = n.rsplit("/", 1)[-1][:-4]
            cat = room(base)
            if cat is None or base in seen:
                continue
            seen.add(base)
            jobs.append(dict(kind="obj", zip=os.path.join(raw, path), name=n, base=base, key=key, source=source, lic=lic, yaw=yaw, lift=lift, cat=cat))
    for meta in glob.glob(os.path.join(raw, "fluentrepo/assets/*/metadata.json")):
        data = json.load(open(meta, encoding="utf8"))
        cat = FLUENT_GROUPS.get(data.get("group"))
        if not cat:
            continue
        folder = os.path.dirname(meta)
        png = glob.glob(os.path.join(folder, "3D", "*.png")) or glob.glob(os.path.join(folder, "Default", "3D", "*.png"))
        if png:
            jobs.append(dict(kind="png", path=png[0], base=os.path.basename(folder), key="fluent", source="Microsoft Fluent Emoji", lic="MIT", cat=cat))
    return jobs


def build(job):
    out = job["out"]
    try:
        if job["kind"] == "png":
            image = Image.open(job["path"]).convert("RGBA")
        else:
            z = zipfile.ZipFile(job["zip"])
            obj = z.read(job["name"]).decode("utf8", "ignore")
            mtl_name = job["name"][:-4] + ".mtl"
            mtl = z.read(mtl_name).decode("utf8", "ignore") if mtl_name in z.namelist() else ""
            texture = None
            match = re.search(r"^map_Kd\s+(.+)$", mtl, re.M)
            if match:
                folder = job["name"].rsplit("/", 1)[0]
                tex_name = folder + "/" + match.group(1).strip().replace("\\", "/")
                if tex_name in z.namelist():
                    texture = Image.open(io.BytesIO(z.read(tex_name))).convert("RGB")
            V, F, C = load_obj(obj, mtl, texture)
            if len(F) == 0 or len(F) > MAX_TRIANGLES:
                return None
            image = render(V, F, C, 320, job["yaw"], 16, job["lift"])
        id = job["key"] + "_" + slug(job["base"])
        folder = os.path.join(out, "webp", job["cat"])
        os.makedirs(folder, exist_ok=True)
        path = os.path.join(folder, id + ".webp")
        sticker(image, LONG_SIDE).save(path, "WEBP", quality=80, method=6)
        return dict(id=id, title=title(job["base"]), category=job["cat"], source=job["source"], license=job["lic"], file=f"webp/{job['cat']}/{id}.webp", bytes=os.path.getsize(path))
    except Exception as error:
        print("ATLANDI", job["base"], error, flush=True)
        return None


def main():
    raw, out = sys.argv[1:3]
    os.makedirs(out, exist_ok=True)
    jobs = model_jobs(raw)
    for job in jobs:
        job["out"] = out
    print("is sayisi", len(jobs), flush=True)
    with multiprocessing.Pool(max(2, (os.cpu_count() or 4) - 2)) as pool:
        items = [x for x in pool.imap_unordered(build, jobs, chunksize=4) if x]
    items.sort(key=lambda x: (x["category"], x["source"], x["title"]))
    json.dump(items, open(os.path.join(out, "catalog.json"), "w", encoding="utf8"), ensure_ascii=False, indent=0)
    print("BITTI", len(items), sum(x["bytes"] for x in items), flush=True)


if __name__ == "__main__":
    main()
