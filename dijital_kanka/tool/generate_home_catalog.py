"""Ev Stüdyosu taslağındaki katalog verisini `lib/data/home_catalog.dart`'a çevirir.

Kaynak: taslak sayfa (`docs/home_studio/index.html`) — odalar, kategoriler, eşyalar, yemekler, sabunlar.
Taslak değişince bu betik yeniden çalıştırılır; Dart dosyası elle düzenlenmez.

Kullanım (dijital_kanka/ içinde): python tool/generate_home_catalog.py
"""
import json
import re

SRC = "docs/home_studio/index.html"
OUT = "lib/data/home_catalog.dart"

# Faz 0 kararı (2026-11-02): sabun türü bir kez alınır, sabunun ŞEKLİ banyo dekor ürünüdür.
SOAP_SHAPES = {
    "name": "Sabun şekli",
    "kind": "draw",
    "items": [
        ["klasik", "Klasik", "soapBar", "#FF9FBF", 0],
        ["kalp", "Kalp", "soapHeart", "#FF7FA0", 60],
        ["yildiz", "Yıldız", "soapStar", "#FFD64A", 80],
        ["bulut", "Bulut", "soapCloud", "#BFE6F5", 80],
        ["ordek", "Ördek", "soapDuck", "#FFE07A", 100],
    ],
}

KIND_DART = {"swatch": "swatch", "wall": "wallpaper", "floor": "floor", "tile": "tile", "draw": "furniture", "blanket": "blanket", "cloth": "cloth"}
ROOM_DART = {"mutfak": "kitchen", "banyo": "bath", "yatak": "bedroom", "salon": "living"}


def js_to_json(text):
    text = re.sub(r"'([^'\\]*(?:\\.[^'\\]*)*)'", lambda m: json.dumps(m.group(1).replace("\\'", "'")), text)
    text = re.sub(r"([{,]\s*)([A-Za-z_]\w*)\s*:", r'\1"\2":', text)
    text = re.sub(r",(\s*[\]}])", r"\1", text)
    return json.loads(text)


def block(src, start, end):
    i = src.index(start) + len(start) - 1
    return src[i:src.index(end, i) + len(end) - 1]


src = open(SRC, encoding="utf8").read()
paints = js_to_json(block(src, "const PAINTS = [", "]];"))
rooms_js = block(src, "const ROOMS = {", "\n};").replace("items: PAINTS", "items: " + json.dumps(paints, ensure_ascii=False))
rooms = js_to_json(rooms_js)
soaps = js_to_json(block(src, "const SOAPS = [", "]];"))
foods = js_to_json(block(src, "const FOODS = [", "\n];"))
groups = js_to_json(block(src, "const FOOD_GROUPS = [", "]];"))

rooms["banyo"]["cat"]["sabun"] = SOAP_SHAPES
rooms["banyo"]["eq"]["sabun"] = "klasik"


def color(c):
    return "null" if not c or c == "rainbow" else "0xFF" + c.lstrip("#").upper()


def s(text):
    return "'" + text.replace("\\", "\\\\").replace("'", "\\'") + "'"


def item(kind, it):
    if kind == "swatch":
        iid, name, col, price = it
        return f"HomeItem({s(iid)}, {s(name)}, color: {color(col)}, price: {price})"
    if kind == "wall":
        iid, name, price = it
        return f"HomeItem({s(iid)}, {s(name)}, style: {s(iid)}, price: {price})"
    if kind == "draw":
        iid, name, style, col, price = it
        return f"HomeItem({s(iid)}, {s(name)}, style: {s(style)}, color: {color(col)}, price: {price})"
    iid, name, style, col, col2, price = it
    return f"HomeItem({s(iid)}, {s(name)}, style: {s(style)}, color: {color(col)}, color2: {color(col2)}, price: {price})"


lines = [
    "// ÜRETİLMİŞ DOSYA — elle düzenleme. Kaynak: docs/home_studio/index.html,",
    "// üretici: tool/generate_home_catalog.py. Adlar şimdilik yalnız TR (EN/ES Faz 9,",
    "// docs/zibo_world_roadmap.md).",
    "",
    "import '../models/home_item.dart';",
    "",
    "const homeRooms = <HomeRoomDef>[",
]
for rid, room in rooms.items():
    lines.append(f"  HomeRoomDef(")
    lines.append(f"    room: HomeRoom.{ROOM_DART[rid]},")
    lines.append(f"    nameTr: {s(room['n'])},")
    lines.append("    defaults: {" + ", ".join(f"{s(k)}: {s(v)}" for k, v in room["eq"].items()) + "},")
    lines.append("    categories: [")
    for cid, cat in room["cat"].items():
        lines.append(f"      HomeCategory({s(cid)}, {s(cat['n'] if 'n' in cat else cat['name'])}, HomeCategoryKind.{KIND_DART[cat['k'] if 'k' in cat else cat['kind']]}, [")
        for it in cat["items"]:
            lines.append(f"        {item(cat['k'] if 'k' in cat else cat['kind'], it)},")
        lines.append("      ]),")
    lines.append("    ],")
    lines.append("  ),")
lines.append("];")
lines.append("")
lines.append("const homeFoodGroups = <String, String>{" + ", ".join(f"{s(g)}: {s(n)}" for g, n in groups) + "};")
lines.append("")
lines.append("/// Ücretsiz olanlar (fiyat 0) günlük ücretsiz yemek hakkından düşer.")
lines.append("const homeFoods = <HomeFood>[")
for fid, name, hunger, price, group in foods:
    lines.append(f"  HomeFood({s(fid)}, {s(name)}, hunger: {hunger}, price: {price}, group: {s(group)}),")
lines.append("];")
lines.append("")
lines.append("/// Sabun türü köpük rengini belirler, bir kez alınır. `foam` null = gökkuşağı.")
lines.append("const homeSoaps = <HomeSoap>[")
for sid, name, foam, stroke, bar, barStroke, price in soaps:
    lines.append(f"  HomeSoap({s(sid)}, {s(name)}, foam: {color(foam)}, foamStroke: {color(stroke)}, bar: {color(bar)}, barStroke: {color(barStroke)}, price: {price}),")
lines.append("];")
lines.append("")
open(OUT, "w", encoding="utf8", newline="\n").write("\n".join(lines))
n_items = sum(len(c["items"]) for r in rooms.values() for c in r["cat"].values())
print(f"{len(rooms)} oda, {sum(len(r['cat']) for r in rooms.values())} kategori, {n_items} eşya, {len(foods)} yemek, {len(soaps)} sabun")
