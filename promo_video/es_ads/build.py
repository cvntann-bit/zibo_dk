"""Zibo İspanyolca reklam fabrikası — 10 konsept × (9:16 + 16:9), 30 / 45 sn, sesli (2026-10-28).

Kullanım (repo kökünden):
    python promo_video/es_ads/build.py list
    python promo_video/es_ads/build.py stills [--only 1,2]       # her sahneden bir kare → out/stills/sheet_*.png
    python promo_video/es_ads/build.py render [--workers 4] [--only 1,5] [--fmt v|h]

Görüntü: index.html (sahne şablonları). Ses: sayfanın window.EVENTS listesi + reels'teki mix/sfx + Suno müziği.
POLİTİKA (Google Ads "sosyal kumar"): oyun / puan / coin / takas / ödül / kazanmak / hediye kutusu YOK;
sahte kullanıcı sayısı, yorum, sağlık veya gelir iddiası YOK. Metinler cinsiyet-nötr İspanyolca.
Konsept psikolojisi: merak boşluğu, tersine psikoloji, tanıdık an (POV), kayıp kaçınma (seri), küçük adım,
seçim/kimlik ("hangi Zibo sensin"), taahhüt (geri sayım), duygusal arkadaşlık, önce/sonra karşıtlığı.
"""
import json
import subprocess
import sys
import urllib.parse
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from reels import build as R  # noqa: E402  (müzik, efekt, miks aynı)

OUT = HERE / "out"
FPS = 30
FMT = {"v": (1080, 1920, "9x16"), "h": (1920, 1080, "16x9")}
END_TAG = "Tu compañero de hábitos"

CONCEPTS = [
    # 1 — Tanıdık an: "pazartesi başlarım" (POV)
    dict(slug="lunes", total=30, track="bouncy", scenes=[
        dict(type="title", sec=3, pal=0, lines=["Tú, cada domingo:"], sub="“El lunes empiezo”", z="zibo_df_pose3"),
        dict(type="pov", sec=8, pal=10, panels=[
            dict(t="Lunes:", s="*no empieza*", z="zibo_df_pose2", fx="womp"),
            dict(t="Martes:", s="“Mejor el próximo lunes”", z="zibo_df_pose1"),
            dict(t="Zibo:", s="¿Y si empezamos HOY?", z="zibo_df_pose4", fx="boing")]),
        dict(type="checklist", sec=7, pal=1, title="Hoy, con Zibo:", items=["Beber agua", "Leer 10 páginas", "Caminar 20 minutos", "Escribir 1 cosa buena"]),
        dict(type="title", sec=4, pal=4, lines=["Pequeños pasos.", "*Gran cambio.*"], z="zibo_king"),
        dict(type="end", pal=0, tag="Empieza hoy, no el lunes")]),
    # 2 — Tersine psikoloji: "bu uygulamayı indirme…"
    dict(slug="no_descargues", total=45, track="bouncy", scenes=[
        dict(type="title", sec=3, pal=9, lines=["*No* descargues", "esta app…"], fx="womp", fxAt=1.2),
        dict(type="title", sec=4, pal=0, lines=["…si no quieres", "un amigo que te", "*anime cada día*"], z="zibo_df_pose3"),
        dict(type="chat", sec=7, pal=1, z="zibo_df_pose3", msgs=[
            dict(z=1, t="¡Buenos días! ☀️ ¿Un vaso de agua?"), dict(t="Ya voy…"),
            dict(z=1, t="¡Eso! Uno menos 💧"), dict(z=1, t="¿Cómo te sientes hoy?")]),
        dict(type="water", sec=5, pal=8, title="Agua de hoy"),
        dict(type="mood", sec=6, pal=3, pick=4, reply="¡Me alegra verte así! 💛"),
        dict(type="features", sec=6, pal=6),
        dict(type="costumes", sec=5, pal=2, title="Y lo vistes|a tu estilo"),
        dict(type="title", sec=3, pal=0, lines=["Ya te avisamos 😉"], z="zibo_df_pose4"),
        dict(type="end", pal=0, tag=END_TAG)]),
    # 3 — Küçük adım: %1 eğrisi
    dict(slug="uno_por_ciento", total=30, track="bright", scenes=[
        dict(type="title", sec=3, pal=6, lines=["Mejora solo *1%*", "cada día"]),
        dict(type="curve", sec=8, pal=7, title="1% cada día", z="zibo_ogrenci"),
        dict(type="title", sec=3, pal=2, lines=["El secreto no es", "la motivación."]),
        dict(type="title", sec=3, pal=4, lines=["Es la *constancia*."], z="zibo_sporcu"),
        dict(type="streak", sec=6, pal=0, to=30, z="zibo_sporcu"),
        dict(type="end", pal=0, tag="1% hoy. 1% mañana.")]),
    # 4 — Duygusal arkadaşlık: "nasılsın diye soran var mı?"
    dict(slug="zibo_si", total=45, track="bright", scenes=[
        dict(type="title", sec=4, pal=10, lines=["¿Alguien te pregunta", "*cómo estás*?"], z="zibo_df_pose1"),
        dict(type="title", sec=3, pal=0, lines=["*Zibo sí.*"], z="zibo_df_pose3", fx="sparkle", fxAt=.5),
        dict(type="chat", sec=8, pal=3, z="zibo_df_pose3", msgs=[
            dict(z=1, t="Hola 👋 ¿Qué tal tu día?"), dict(t="Regular…"),
            dict(z=1, t="Cuéntame. Aquí estoy."), dict(z=1, t="Escribe 3 cosas buenas de hoy 💛")]),
        dict(type="checklist", sec=6, pal=0, title="Gratitud de hoy", z="zibo_gentleman",
             items=["El café de la mañana", "Un mensaje bonito", "Terminé lo que empecé"]),
        dict(type="mood", sec=6, pal=8, pick=3, reply="Poco a poco, juntos 💛"),
        dict(type="streak", sec=5, pal=6, to=14, z="zibo_gentleman"),
        dict(type="title", sec=4, pal=4, lines=["Un amigo *de bolsillo*", "que te acompaña"], z="zibo_gentleman"),
        dict(type="features", sec=5, pal=1),
        dict(type="end", pal=0, tag="Aquí tienes compañía")]),
    # 5 — Kimlik/seçim: "hangi Zibo sensin?"
    dict(slug="elige_tu_zibo", total=30, track="pixel", scenes=[
        dict(type="title", sec=2.5, pal=2, lines=["¿Cuál eres tú?"]),
        dict(type="choose", sec=6, pal=7, q="Elige tu Zibo", pick=1, opts=[
            dict(z="zibo_samurai", name="Samurái"), dict(z="zibo_astronot", name="Astronauta"), dict(z="zibo_king", name="Rey")]),
        dict(type="title", sec=4, pal=1, lines=["Ahora imagínalo", "*recordándote tus metas*"], z="zibo_astronot"),
        dict(type="checklist", sec=5, pal=0, title="Tu día, más fácil", z="zibo_astronot", items=["Metas", "Agua", "Enfoque"]),
        dict(type="costumes", sec=6, pal=2, title="+40 looks|para elegir"),
        dict(type="end", pal=0, tag="¿Cuál será el tuyo?")]),
    # 6 — "Zibo ile bir gün" (zaman damgalı montaj)
    dict(slug="un_dia", total=45, track="pixel", scenes=[
        dict(type="title", sec=3, pal=0, lines=["Así es *un día*", "con Zibo"]),
        dict(type="title", sec=3.5, pal=5, lines=["7:00 ☀️", "Buenos días"], z="zibo_df_pose3", sub="Una frase para empezar"),
        dict(type="water", sec=5, pal=8, title="10:00 · Agua"),
        dict(type="checklist", sec=6, pal=1, title="12:00 · Tus metas", items=["Responder correos", "Comer bien", "Caminar 20 min", "Leer 10 páginas"]),
        dict(type="timer", sec=5, pal=6, title="16:00 · Enfoque"),
        dict(type="mood", sec=5, pal=3, title="19:00 · ¿Cómo estás?", pick=4, reply="¡Buen día hoy! 💛"),
        dict(type="title", sec=3.5, pal=2, lines=["22:00 🌙", "Anota tu sueño"], z="zibo_df_pose5"),
        dict(type="streak", sec=5, pal=0, to=7, label="DÍAS SEGUIDOS"),
        dict(type="end", pal=0, tag="Un día mejor, cada día")]),
    # 7 — Taahhüt: geri sayım
    dict(slug="cuenta_atras", total=30, track="pixel", scenes=[
        dict(type="title", sec=4, pal=6, lines=["Piensa en *un hábito*", "que quieras empezar"], z="zibo_df_pose1"),
        dict(type="countdown", sec=3.5, pal=2, cap="Piénsalo…"),
        dict(type="title", sec=2, pal=0, lines=["¿Lo tienes?"], z="zibo_df_pose4"),
        dict(type="title", sec=2.5, pal=9, lines=["Ahora", "*no lo olvides*."]),
        dict(type="checklist", sec=6, pal=1, title="Zibo te lo recuerda", items=["Beber agua", "Leer 10 páginas", "Caminar 20 min", "Ahorrar un poco"]),
        dict(type="streak", sec=5, pal=4, to=21),
        dict(type="end", pal=0, tag="Tu hábito empieza hoy")]),
    # 8 — Önce / sonra karşıtlığı
    dict(slug="antes_despues", total=45, track="bouncy", scenes=[
        dict(type="title", sec=2.5, pal=10, lines=["*Antes* de Zibo"], z="zibo_df_pose2"),
        dict(type="pov", sec=6, pal=10, panels=[
            dict(t="Metas|olvidadas", z="zibo_df_pose2", fx="womp"), dict(t="Agua:|0 vasos", z="zibo_df_pose1"),
            dict(t="Ánimo:|😐", z="zibo_df_pose2", fx="womp")]),
        dict(type="title", sec=2.5, pal=0, lines=["*Después* de Zibo"], z="zibo_df_pose3", fx="sparkle", fxAt=.5),
        dict(type="checklist", sec=5, pal=1, title="Metas cumplidas", items=["Leer 10 páginas", "Caminar 20 min", "Ordenar el escritorio"]),
        dict(type="water", sec=5, pal=8, title="Agua: ¡2 litros!"),
        dict(type="mood", sec=5, pal=3, pick=4, reply="¡Así sí! 💛"),
        dict(type="features", sec=5, pal=6),
        dict(type="costumes", sec=5, pal=2),
        dict(type="title", sec=3.5, pal=4, lines=["Tu mejor versión", "empieza *hoy*"], z="zibo_altin"),
        dict(type="end", pal=0, tag=END_TAG)]),
    # 9 — Merak: mini test
    dict(slug="test", total=30, track="bouncy", scenes=[
        dict(type="title", sec=3, pal=2, lines=["Test rápido:", "*¿Qué Zibo eres?*"]),
        dict(type="choose", sec=6, pal=7, q="¿Qué haces|al despertar?", pick=1, opts=[
            dict(z="zibo_sporcu", name="Agua primero"), dict(z="zibo_punk", name="Miro el móvil"), dict(z="zibo_astronot", name="5 min más")]),
        dict(type="title", sec=3.5, pal=3, lines=["Resultado:", "*Zibo Punk* 😄"], z="zibo_punk", sub="Necesitas un compañero"),
        dict(type="features", sec=6, pal=1, title="Él te ayuda con:"),
        dict(type="costumes", sec=5, pal=2, title="¿Y tú,|cuál eres?"),
        dict(type="end", pal=0, tag="Descubre tu Zibo")]),
    # 10 — Kayıp kaçınma: seriyi bozma
    dict(slug="racha", total=45, track="pixel", scenes=[
        dict(type="title", sec=2.5, pal=0, lines=["Día *1*"], z="zibo_df_pose3"),
        dict(type="streak", sec=7, pal=4, to=30, z="zibo_sporcu"),
        dict(type="title", sec=3, pal=10, lines=["Y un día…", "se te *olvida*"], z="zibo_df_pose2", fx="womp", fxAt=1.0),
        dict(type="title", sec=2.5, pal=9, lines=["¿Perder 30 días?"], z="zibo_df_pose1"),
        dict(type="title", sec=3.5, pal=1, lines=["Sin miedo:", "*Protector de racha*"], z="streak_freeze_icon.webp", zh=520, fx="sparkle", fxAt=.8),
        dict(type="checklist", sec=5, pal=0, title="Y sigues sumando", items=["Beber agua", "Leer 10 páginas", "Caminar 20 min"]),
        dict(type="features", sec=5, pal=6),
        dict(type="costumes", sec=5, pal=2, title="Tu Zibo,|tu estilo"),
        dict(type="title", sec=3, pal=4, lines=["No rompas", "*tu racha*"], z="zibo_king"),
        dict(type="end", pal=0, tag="Tu racha te espera")]),
]


def specs():
    out = []
    for i, c in enumerate(CONCEPTS, 1):
        tr = R.TRACKS[c["track"]]
        sp = dict(c, id=i, bpm=tr["bpm"], type="ad", startBar=tr["first"])
        out.append(sp)
    return out


def fname(sp, fmt):
    return f"zibo_es_{sp['id']:02d}_{sp['slug']}_{sp['total']}s_{FMT[fmt][2]}.mp4"


def url(sp, fmt):
    page = {k: sp[k] for k in ("bpm", "total", "scenes")}
    return (HERE / "index.html").resolve().as_uri() + f"?f={fmt}&cap=1&spec=" + urllib.parse.quote(json.dumps(page, ensure_ascii=False))


def render_one(job, stills=False):
    sp, fmt = job
    from playwright.sync_api import sync_playwright
    w, h, _ = FMT[fmt]
    OUT.mkdir(exist_ok=True)
    with sync_playwright() as p:
        br = p.chromium.launch(channel="chrome", headless=True)
        pg = br.new_page(viewport={"width": w, "height": h})
        pg.goto(url(sp, fmt))
        pg.wait_for_function("window.READY === true", timeout=90000)
        dur = pg.evaluate("window.DURATION")
        if stills:
            from PIL import Image
            d = OUT / "stills"
            d.mkdir(exist_ok=True)
            ts = pg.evaluate("window.SCENE_MIDS")
            shots = []
            for t in ts:
                pg.evaluate(f"seek({t})")
                f = d / f"{sp['id']:02d}_{fmt}_{t:05.1f}.png"
                pg.screenshot(path=str(f))
                shots.append(f)
            br.close()
            tw, th = (216, 384) if fmt == "v" else (384, 216)
            cols = 6
            rows = -(-len(shots) // cols)
            sheet = Image.new("RGB", (cols * tw, rows * th), "white")
            for k, f in enumerate(shots):
                sheet.paste(Image.open(f).convert("RGB").resize((tw, th)), ((k % cols) * tw, (k // cols) * th))
            sheet.save(d / f"sheet_{sp['id']:02d}_{sp['slug']}_{fmt}.png")
            return sp["id"], fmt
        events = pg.evaluate("window.EVENTS")
        wav = OUT / f"_{sp['id']:02d}_{fmt}.wav"
        R.mix(sp, events, dur, wav)
        target = OUT / fname(sp, fmt)
        ff = subprocess.Popen([R.FF, "-y", "-loglevel", "error", "-f", "image2pipe", "-framerate", str(FPS), "-c:v", "mjpeg", "-i", "-",
                               "-i", str(wav), "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
                               "-c:a", "aac", "-b:a", "192k", "-t", f"{dur:.3f}", "-movflags", "+faststart", str(target)],
                              stdin=subprocess.PIPE)
        for i in range(int(dur * FPS)):
            pg.evaluate(f"seek({i / FPS})")
            ff.stdin.write(pg.screenshot(type="jpeg", quality=92))
        ff.stdin.close()
        ff.wait()
        br.close()
        wav.unlink()
    return target.name, round(dur, 1), round(target.stat().st_size / 1e6, 1)


def jobs(argv):
    only = {int(x) for x in argv[argv.index("--only") + 1].split(",")} if "--only" in argv else None
    fmts = [argv[argv.index("--fmt") + 1]] if "--fmt" in argv else ["v", "h"]
    return [(s, f) for s in specs() if not only or s["id"] in only for f in fmts]


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "list":
        for s in specs():
            print(s["id"], s["slug"], s["total"], "sn", s["track"], len(s["scenes"]), "sahne")
    elif cmd == "stills":
        import functools
        with ProcessPoolExecutor(max_workers=4) as ex:
            for r in ex.map(functools.partial(render_one, stills=True), jobs(sys.argv)):
                print("sheet", r, flush=True)
    elif cmd == "render":
        wk = int(sys.argv[sys.argv.index("--workers") + 1]) if "--workers" in sys.argv else 4
        todo = jobs(sys.argv)
        print(len(todo), "video,", wk, "işçi", flush=True)
        with ProcessPoolExecutor(max_workers=wk) as ex:
            for r in ex.map(render_one, todo):
                print("OK", r, flush=True)
