"""Ev Stüdyosu taslağındaki katalog verisini `lib/data/home_catalog.dart`'a çevirir.

Kaynak: taslak sayfa (`docs/home_studio/index.html`) — odalar, kategoriler, eşyalar, yemekler, sabunlar.
Taslak değişince bu betik yeniden çalıştırılır; Dart dosyası elle düzenlenmez.

EN/ES adlar `tool/home_catalog_i18n.json`'dan gelir (TR ad → [EN, ES]); yeni bir TR ad
eklenince oraya da eklenmeli, yoksa betik hangi adların eksik olduğunu yazıp durur.

Kullanım (dijital_kanka/ içinde): python tool/generate_home_catalog.py
"""
import json
import re

SRC = "docs/home_studio/index.html"
I18N = "tool/home_catalog_i18n.json"
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

# Faz 6 (2026-11-03): yalnızca etkinlik ödülü olarak kazanılan sezonluk eşyalar.
# Mağazada satılmaz (eventOnly); fiyat yalnızca nadirlik kademesi içindir.
EVENT_ITEMS = {
    ("salon", "kose"): [
        ["cam", "Yılbaşı çamı", "xmasTree", "#2E8B57", 900],
        ["kardan", "Kardan adam", "snowman", "#F2564B", 600],
    ],
    ("salon", "puf"): [
        ["hediye", "Hediye kutuları", "giftBoxes", "#F2564B", 400],
    ],
}

# Abonelere özel seriler (2026-11-06, docs/subscribe_model.md): yalnız Dart'ta çizilir
# (lib/widgets/home_art/luxe_art.dart). Son öğe katman: "pro" = Altın Saray, "proPlus" = Elmas.
GOLD, ICE = "#FFF4DE", "#CDEFFF"
PRO_ITEMS = {
    ("mutfak", "buzdolabi"): [["saray", "Saray buzdolabı", "royalFridge", GOLD, 1400, "pro"], ["kristal", "Kristal buzdolabı", "crystalFridge", ICE, 1900, "proPlus"]],
    ("mutfak", "sarkit"): [["avize", "Altın avize", "chandelierGold", "#E2B64A", 1000, "pro"], ["kavize", "Kristal avize", "chandelierCrystal", ICE, 1400, "proPlus"]],
    ("banyo", "kuvet"): [["saray", "Saray küveti", "royalTub", GOLD, 1600, "pro"], ["kristal", "Kristal küvet", "crystalTub", ICE, 2200, "proPlus"]],
    ("banyo", "ayna"): [["tac", "Taçlı ayna", "mirrorCrown", "#E2B64A", 800, "pro"], ["elmas", "Elmas ayna", "mirrorDiamond", ICE, 1100, "proPlus"]],
    ("yatak", "yatak"): [["saray", "Kraliyet yatağı", "bedRoyal", "#B3263A", 1800, "pro"], ["kristal", "Kristal yatak", "bedCrystal", "#A9DDF2", 2500, "proPlus"]],
    ("yatak", "dolap"): [["saray", "Saray gardırobu", "wardrobeRoyal", GOLD, 1400, "pro"], ["kristal", "Kristal gardırop", "wardrobeCrystal", ICE, 1900, "proPlus"]],
    ("salon", "kanepe"): [["taht", "Taht kanepe", "sofaThrone", "#B3263A", 1800, "pro"], ["kristal", "Buz kanepe", "sofaCrystal", ICE, 2500, "proPlus"]],
    ("salon", "lambader"): [["samdan", "Altın şamdan", "floorCandelabra", "#E2B64A", 900, "pro"], ["prizma", "Prizma lambader", "floorLampCrystal", ICE, 1300, "proPlus"]],
}
for _rid in ("mutfak", "yatak", "salon"):
    PRO_ITEMS[(_rid, "desen")] = [["damask", "Altın damask", 800, "pro"], ["elmas", "Elmas kafes", 1100, "proPlus"]]
for _rid in ("mutfak", "banyo", "yatak", "salon"):
    PRO_ITEMS[(_rid, "zemin")] = [["mermer", "Mermer", "mermer", "#F7F2E9", "#CBBFAE", 1000, "pro"], ["kristal", "Kristal zemin", "kristal", "#DDF5FF", "#A6DCF2", 1400, "proPlus"]]

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
for (rid, cid), extra in EVENT_ITEMS.items():
    rooms[rid]["cat"][cid]["items"] += [it + ["event"] for it in extra]
for (rid, cid), extra in PRO_ITEMS.items():
    ids = {it[0] for it in rooms[rid]["cat"][cid]["items"]}
    assert not ids & {it[0] for it in extra}, (rid, cid, ids & {it[0] for it in extra})
    rooms[rid]["cat"][cid]["items"] += [list(it) for it in extra]
rooms["banyo"]["eq"]["sabun"] = "klasik"


I18N_NAMES = json.load(open(I18N, encoding="utf8"))
missing = set()


def tr(name):
    """Ad argümanından sonra eklenen EN/ES adlar."""
    pair = I18N_NAMES.get(name)
    if pair is None:
        missing.add(name)
        return ""
    return f", nameEn: {s(pair[0])}, nameEs: {s(pair[1])}"


def color(c):
    return "null" if not c or c == "rainbow" else "0xFF" + c.lstrip("#").upper()


def s(text):
    return "'" + text.replace("\\", "\\\\").replace("'", "\\'") + "'"


TIER_DART = {"pro": ", requiredTier: SubscriptionTier.pro", "proPlus": ", requiredTier: SubscriptionTier.proPlus", "event": ", eventOnly: true"}


def item(kind, it):
    flag = ""
    if it and it[-1] in TIER_DART:
        flag, it = TIER_DART[it[-1]], it[:-1]
    return _item(kind, it)[:-1] + flag + ")"


def _item(kind, it):
    if kind == "swatch":
        iid, name, col, price = it
        return f"HomeItem({s(iid)}, {s(name)}{tr(name)}, color: {color(col)}, price: {price})"
    if kind == "wall":
        iid, name, price = it
        return f"HomeItem({s(iid)}, {s(name)}{tr(name)}, style: {s(iid)}, price: {price})"
    if kind == "draw":
        iid, name, style, col, price = it[:5]
        return f"HomeItem({s(iid)}, {s(name)}{tr(name)}, style: {s(style)}, color: {color(col)}, price: {price})"
    iid, name, style, col, col2, price = it
    return f"HomeItem({s(iid)}, {s(name)}{tr(name)}, style: {s(style)}, color: {color(col)}, color2: {color(col2)}, price: {price})"


lines = [
    "// ÜRETİLMİŞ DOSYA — elle düzenleme. Kaynak: docs/home_studio/index.html,",
    "// üretici: tool/generate_home_catalog.py. EN/ES adlar: tool/home_catalog_i18n.json.",
    "",
    "import '../models/home_item.dart';",
    "import '../models/subscription_tier.dart';",
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
        cname = cat['n'] if 'n' in cat else cat['name']
        lines.append(f"      HomeCategory({s(cid)}, {s(cname)}{tr(cname)}, HomeCategoryKind.{KIND_DART[cat['k'] if 'k' in cat else cat['kind']]}, [")
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
    lines.append(f"  HomeFood({s(fid)}, {s(name)}{tr(name)}, hunger: {hunger}, price: {price}, group: {s(group)}),")
lines.append("];")
lines.append("")
lines.append("/// Sabun türü köpük rengini belirler, bir kez alınır. `foam` null = gökkuşağı.")
lines.append("const homeSoaps = <HomeSoap>[")
for sid, name, foam, stroke, bar, barStroke, price in soaps:
    lines.append(f"  HomeSoap({s(sid)}, {s(name)}{tr(name)}, foam: {color(foam)}, foamStroke: {color(stroke)}, bar: {color(bar)}, barStroke: {color(barStroke)}, price: {price}),")
lines.append("];")
lines.append("")
if missing:
    raise SystemExit("Çevirisi eksik adlar (tool/home_catalog_i18n.json): " + ", ".join(sorted(missing)))
open(OUT, "w", encoding="utf8", newline="\n").write("\n".join(lines))

# Yönetici uygulaması (zibo_admin) için aranabilir anahtar listesi: config/home'daki
# fiyat ezmesi / sınırlı süre / Pro'ya özel listeleri bu anahtarları kullanır.
ROOM_TR = {"mutfak": "Mutfak", "banyo": "Banyo", "yatak": "Yatak odası", "salon": "Salon"}
TIER_TR = {"pro": "Pro", "proPlus": "Pro+", "event": "Etkinlik"}
admin = [
    "// ÜRETİLMİŞ DOSYA — elle düzenleme. Üretici: dijital_kanka/tool/generate_home_catalog.py.",
    "// Zibo'nun Evi kataloğundaki satılabilir her şeyin config/home anahtarı.",
    "",
    "/// (anahtar, görünen ad, taban fiyat ZC, katman: '' / Pro / Pro+ / Etkinlik)",
    "const homeCatalogKeys = <(String, String, int, String)>[",
]
for rid, room in rooms.items():
    for cid, cat in room["cat"].items():
        cname = cat["n"] if "n" in cat else cat["name"]
        for it in cat["items"]:
            tier = TIER_TR.get(it[-1], "")
            price = [v for v in it if isinstance(v, int)][-1]
            admin.append(f"  ({s(rid + ':' + cid + ':' + it[0])}, {s(ROOM_TR[rid] + ' · ' + cname + ' · ' + it[1])}, {price}, {s(tier)}),")
for fid, name, hunger, price, group in foods:
    admin.append(f"  ({s('food:' + fid)}, {s('Yemek · ' + name)}, {price}, ''),")
for sid, name, *rest in soaps:
    admin.append(f"  ({s('soap:' + sid)}, {s('Sabun · ' + name)}, {rest[-1]}, ''),")
admin.append("];")
admin.append("")
open("../zibo_admin/lib/home_catalog_keys.dart", "w", encoding="utf8", newline="\n").write("\n".join(admin))
n_items = sum(len(c["items"]) for r in rooms.values() for c in r["cat"].values())
print(f"{len(rooms)} oda, {sum(len(r['cat']) for r in rooms.values())} kategori, {n_items} eşya, {len(foods)} yemek, {len(soaps)} sabun")
