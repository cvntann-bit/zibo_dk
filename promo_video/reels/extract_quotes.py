"""Uygulamanın İngilizce söz havuzlarını (lib/data/*_quotes.dart → <ad>QuotesEn) reels/quotes_en.json'a çıkarır.

Kullanım (repo kökünden):  python promo_video/reels/extract_quotes.py
Dart dizgelerini (tek/çift tırnak, ters bölü kaçışları) küçük bir durum makinesiyle okur.
"""
import json
from pathlib import Path

DATA = Path(__file__).parents[2] / "dijital_kanka" / "lib" / "data"
POOLS = ["goal", "gratitude", "water", "mood", "focus", "dream", "money"]


def strings(body):
    out, i, n = [], 0, len(body)
    while i < n:
        c = body[i]
        if c == "/" and body[i:i + 2] == "//":          # satır yorumu
            i = body.find("\n", i)
            i = n if i < 0 else i
            continue
        if c in "'\"":
            q, i, buf = c, i + 1, []
            while i < n and body[i] != q:
                if body[i] == "\\" and i + 1 < n:
                    i += 1
                    buf.append({"n": " "}.get(body[i], body[i]))
                else:
                    buf.append(body[i])
                i += 1
            out.append("".join(buf))
        i += 1
    return out


def main():
    res = {}
    for pool in POOLS:
        src = (DATA / f"{pool}_quotes.dart").read_text(encoding="utf-8")
        start = src.index(f"{pool}QuotesEn")
        start = src.index("[", start) + 1
        end = src.index("];", start)
        res[pool] = strings(src[start:end])
        print(pool, len(res[pool]), "|", res[pool][0][:70])
    (Path(__file__).parent / "quotes_en.json").write_text(json.dumps(res, ensure_ascii=False, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
