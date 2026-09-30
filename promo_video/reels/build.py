"""Zibo Reels fabrikası — 46 İngilizce reels videosunu (1080x1920, sesli) üretir, açıklamalarıyla zip'ler.

Kullanım (repo kökünden):
    python promo_video/reels/build.py list                   # video listesi
    python promo_video/reels/build.py stills [tip ...]       # her tipten örnek kareler + önizleme tablosu (out/stills)
    python promo_video/reels/build.py render [--workers 4] [--only 1,5,9]   # videoları üret
    python promo_video/reels/build.py pack                   # out/*.mp4 + captions.csv + README → Zibo_Reels_Pack.zip

Görüntü: index.html (şablonlar). Ses: sayfanın ürettiği window.EVENTS listesi + sfx.py efektleri + Suno müziği
(müzik dosyaları promo_video/ altında; vuruş ızgaraları analyze.py/beatgrid.py ile ölçüldü).
"""
import csv
import functools
import json
import subprocess
import sys
import urllib.parse
import zipfile
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import imageio_ffmpeg
import numpy as np

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import sfx  # noqa: E402

OUT = HERE / "out"
FF = imageio_ffmpeg.get_ffmpeg_exe()
FPS = 30
QUOTES = json.loads((HERE / "quotes_en.json").read_text(encoding="utf-8"))

# Müzik: dosya, bpm, ilk ölçü başı (sn), kullanılabilir ilk/son ölçü, bell notalarını o tona çeviren oran, akor notaları
TRACKS = {
    "bouncy": dict(file="Bouncy Finale.mp3", bpm=100.0, d0=0.29, first=0, last=27, key=392.0 / 523.3,
                   chime=(392.0, 493.9, 587.3, 784.0)),
    "pixel": dict(file="Pixel Dash.mp3", bpm=144.46, d0=0.176, first=4, last=84, key=1.0,
                  chime=(523.3, 659.3, 784.0, 1046.5)),
    "bright": dict(file="From Sad to Bright.mp3", bpm=109.98, d0=0.44, first=4, last=26, key=392.0 / 523.3,
                   chime=(392.0, 493.9, 587.3, 784.0)),
}
MIN_BARS = dict(quote=5, reveal=5, satisfy=6, tip=6, pov=6, trailer=6)
TARGET = dict(quote=12.0, reveal=11.5, satisfy=12.5, tip=14.0, pov=12.5, trailer=14.0)

COSTUMES = {  # dosya → uygulamadaki İngilizce ad
    "zibo_king": "King Zibo", "zibo_astronot": "Astronaut Zibo", "zibo_korsan": "Pirate Zibo", "zibo_samurai": "Samurai Zibo",
    "zibo_altin": "Golden Zibo", "zibo_elmas": "Diamond-Plated Zibo", "zibo_cyborg": "Cyborg Zibo", "zibo_gladyator": "Gladiator Zibo",
    "zibo_punk": "Punk Zibo", "zibo_gentleman": "Gentleman Zibo", "zibo_hippi": "Hippie Zibo", "zibo_rapci": "Rapper Zibo",
    "zibo_sporcu": "Athlete Zibo", "zibo_hoca": "Professor Zibo", "zibo_asker": "Soldier Zibo", "zibo_zombi": "Zombie Zibo"}
COS = list(COSTUMES)

HASH_BASE = "#zibo #habittracker #selfimprovement #digitalbuddy #dailyhabits #productivity #mindset #wellness #mobileapp"
HASH_TYPE = dict(quote="#quotes #dailyquotes #motivation", reveal="#unboxing #costume #cutecharacter",
                 satisfy="#satisfying #oddlysatisfying #asmr", tip="#tips #habits #lifehacks", pov="#pov #relatable #funny", trailer="#movietrailer #cinematic #funny")
CTA = "Free on Google Play. Link in bio!"

SATISFY = [("water", 1), ("water", 4), ("coins", 0), ("coins", 5), ("checks", 2), ("checks", 8),
           ("streak", 3), ("shelf", 6), ("shelf", 9), ("costumes", 7)]
SATISFY_EXTRA = [("streak", 6), ("costumes", 3)]
TIPS = [
    ("3 tiny habits", ["Drink a glass of water", "Write one thing you're grateful for", "Make your bed"],
     ["su_kahramani_rozet.webp", "sükran_rozeti.webp", "ilk_adim_rozet.webp"]),
    ("Morning routine", ["Water first", "Five minutes of stretching", "Plan your top 3 tasks"],
     ["su_kahramani_rozet.webp", "denge_ustasi_rozet.webp", "bir_hafta_seri_rozet.webp"]),
    ("Evening wind-down", ["Put your phone away", "Write tomorrow's to-do list", "Note one win from today"],
     ["demir_irade_rozet.webp", "ruya_yorumcusu_rozet.webp", "sükran_rozeti.webp"]),
    ("Stay consistent", ["Start tiny", "Same time every day", "Never miss twice"],
     ["ilk_adim_rozet.webp", "bir_hafta_seri_rozet.webp", "demir_irade_rozet.webp"]),
    ("Focus boosters", ["One task at a time", "Set a 25-minute timer", "Phone out of sight"],
     ["denge_ustasi_rozet.webp", "bir_hafta_seri_rozet.webp", "demir_irade_rozet.webp"]),
    ("Money habits", ["Track every spend", "Save first, spend later", "Wait a day before buying"],
     ["birikim_ustasi_rozet.webp", "birikim_ustasi_rozet.webp", "denge_ustasi_rozet.webp"]),
    ("Mood boosters", ["Step outside for a bit", "Log how you feel", "Message a friend"],
     ["ruh_hali_rozet.webp", "ruh_hali_rozet.webp", "sükran_rozeti.webp"]),
    ("Better evenings", ["Same bedtime daily", "Screens off early", "Write down your dreams"],
     ["ruya_yorumcusu_rozet.webp", "denge_ustasi_rozet.webp", "ruya_yorumcusu_rozet.webp"]),
]
POV = [
    ("tomorrow", [dict(t="POV: you said “I'll start tomorrow”", z="zibo_df_pose1.webp"),
                  dict(t="The next day:", s="“I'll start tomorrow”", z="zibo_df_pose2.webp"),
                  dict(t="Zibo:", s="*stares*", z="zibo_df_pose4.webp", fx="womp"),
                  dict(t="Okay, okay... today.", z="zibo_df_pose3.webp", fx="coin")]),
    ("goals", [dict(t="My goals:", s="Read, walk, drink water", z="zibo_df_pose1.webp"),
               dict(t="Me at 11:59 pm:", s="*does nothing*", z="zibo_df_pose2.webp"),
               dict(t="Zibo:", s="Check. Them. Off.", z="zibo_df_pose4.webp", fx="womp"),
               dict(t="Done. +30 ZC", z="zibo_df_pose3.webp", fx="coin")]),
    ("streak", [dict(t="Day 29 of my streak...", z="zibo_df_pose3.webp"),
                dict(t="Me, forgetting to log it", z="zibo_df_pose2.webp", fx="womp"),
                dict(t="Zibo:", s="Streak Freeze, buddy.", z="zibo_df_pose4.webp"),
                dict(t="Streak saved!", z="zibo_astronot.webp", fx="coin")]),
    ("water", [dict(t="Me: “I'll drink water later”", z="zibo_df_pose1.webp"),
               dict(t="8 hours later...", z="zibo_df_pose2.webp", fx="womp"),
               dict(t="Zibo:", s="Glass. Now.", z="zibo_df_pose4.webp"),
               dict(t="Hydrated hero.", z="zibo_samurai.webp", fx="coin")]),
    ("costume", [dict(t="Me: “I'll save my coins”", z="zibo_df_pose1.webp"),
                 dict(t="Sees Golden Zibo", z="zibo_altin.webp", fx="sparkle"),
                 dict(t="Me: take all my coins", z="zibo_df_pose2.webp"),
                 dict(t="Worth it.", z="zibo_king.webp", fx="coin")]),
    ("focus", [dict(t="Me: “25 minutes of focus”", z="zibo_df_pose1.webp"),
               dict(t="My phone: bzzzt", z="zibo_df_pose2.webp", fx="womp"),
               dict(t="Zibo:", s="No. Focus.", z="zibo_df_pose4.webp"),
               dict(t="Focus complete!", z="zibo_hoca.webp", fx="coin")]),
]

POV_EXTRA = [
    ("alarm", [dict(t="Me: “I'll work out at 6 am”", z="zibo_df_pose1.webp"),
               dict(t="My alarm at 6 am:", s="*rings*", z="zibo_df_pose2.webp", fx="womp"),
               dict(t="Me: “Five more minutes”", z="zibo_df_pose2.webp"),
               dict(t="Zibo:", s="Up. Coins. Now.", z="zibo_df_pose4.webp"),
               dict(t="Got up. Coins earned.", z="zibo_sporcu.webp", fx="coin")]),
    ("todo", [dict(t="My to-do list: 47 items", z="zibo_df_pose1.webp"),
              dict(t="What I finished: 0", z="zibo_df_pose2.webp", fx="womp"),
              dict(t="Zibo:", s="Start with three.", z="zibo_df_pose4.webp"),
              dict(t="Three done. Feels good.", z="zibo_df_pose3.webp", fx="coin")]),
    ("gratitude", [dict(t="Me at 11 pm: “Life is hard”", z="zibo_df_pose1.webp"),
                   dict(t="Zibo:", s="Name one good thing.", z="zibo_df_pose4.webp"),
                   dict(t="Me: “...the tea was good”", z="zibo_df_pose2.webp"),
                   dict(t="Gratitude logged.", z="zibo_gentleman.webp", fx="coin")]),
    ("gamehall", [dict(t="Me: “One quick game”", z="zibo_df_pose1.webp"),
                  dict(t="3 hours later...", z="zibo_df_pose2.webp", fx="womp"),
                  dict(t="Zibo:", s="Daily plays are limited, buddy.", z="zibo_df_pose4.webp"),
                  dict(t="Fine. Back to my goals.", z="zibo_punk.webp", fx="coin")]),
]
TRAILERS = [
    ("hero", "zibo_king", [dict(t=["IN A WORLD", "OF UNFINISHED GOALS"], len=5), dict(t=["ONE TINY BUDDY"], len=3),
                           dict(t=["DARED TO START", "TODAY"], len=4), dict(z="zibo_king", len=5), dict(t=["TINY STEPS.", "BIG CHANGE."], len=4)]),
    ("streak", "zibo_astronot", [dict(t=["DAY 1"], len=2), dict(t=["DAY 7"], len=2), dict(t=["DAY 30"], len=2),
                                 dict(t=["THE STREAK", "NEVER ENDS"], len=4), dict(z="zibo_astronot", len=5), dict(t=["KEEP YOUR", "STREAK"], len=4)]),
    ("coins", "zibo_altin", [dict(t=["THEY SAID", "COINS CAN'T BUY", "HAPPINESS"], len=5), dict(t=["THEY WERE", "WRONG"], len=3),
                             dict(z="zibo_altin", len=5), dict(t=["ZIBO COINS"], len=3), dict(t=["COMING TO", "YOUR PHONE"], len=4)]),
    ("space", "zibo_astronot", [dict(t=["HOUSTON,"], len=2), dict(t=["WE HAVE", "A HABIT"], len=4), dict(z="zibo_astronot", len=5),
                                dict(t=["MISSION:", "DRINK WATER"], len=4), dict(t=["STATUS:", "HYDRATED"], len=4)]),
    ("pirate", "zibo_korsan", [dict(t=["ONE PIRATE."], len=3), dict(t=["SEVEN GAMES."], len=3), dict(t=["ENDLESS COINS."], len=3),
                               dict(z="zibo_korsan", len=5), dict(t=["GAME HALL", "OPEN NOW"], len=4)]),
    ("glowup", "zibo_samurai", [dict(t=["EVERY HERO", "NEEDS A COSTUME"], len=5), dict(z="zibo_samurai", len=3), dict(z="zibo_punk", len=3),
                                dict(z="zibo_elmas", len=3), dict(t=["DRESS YOUR", "BUDDY"], len=4)]),
]
BOXES = [("#E8553D", "#F26A52"), ("#3B63C9", "#5B7BD6"), ("#2FBF71", "#4FD58D"), ("#8E5BE6", "#A77BF0"), ("#14B8A6", "#3DD1BF")]
REVEALS = ["zibo_king", "zibo_astronot", "zibo_korsan", "zibo_samurai", "zibo_altin", "zibo_elmas", "zibo_cyborg",
           "zibo_gladyator", "zibo_punk", "zibo_gentleman"]
QUOTE_PICK = ([("goal", i) for i in (0, 1, 2, 8, 12, 20)] + [("water", 1), ("water", 2), ("money", 1), ("focus", 1),
              ("mood", 0), ("gratitude", 0)])
QUOTE_LABEL = dict(goal="Stay consistent", water="Hydrate", money="Money tip", focus="Focus time", mood="Mood check",
                   gratitude="Gratitude")


def pick_track(kind, i):
    order = dict(quote=["bright", "bouncy"], reveal=["pixel", "bouncy"], satisfy=["bouncy", "pixel"],
                 tip=["bright", "bouncy"], pov=["pixel", "bouncy"], trailer=["pixel", "bouncy"])[kind]
    return order[i % 2]


def finalize(spec, i):
    tr = TRACKS[spec["track"]]
    bar = 240 / tr["bpm"]
    bars = max(MIN_BARS[spec["type"]], round(TARGET[spec["type"]] / bar))
    if spec["type"] == "trailer":
        bars = -(-(2 + sum(c["len"] for c in spec["cards"])) // 4) + 1
    lo, hi = tr["first"], tr["last"] - bars
    spec.update(bpm=tr["bpm"], bars=bars, startBar=lo + (i * 7) % max(1, hi - lo + 1), variant=i)
    return spec


def specs():
    out, n = [], 0

    def add(**kw):
        nonlocal n
        n += 1
        sp = dict(id=n, **kw)
        sp["track"] = pick_track(sp["type"], n)
        out.append(finalize(sp, n))

    for k, (pool, idx) in enumerate(QUOTE_PICK):
        add(type="quote", kind=pool, text=QUOTES[pool][idx], label=QUOTE_LABEL[pool], pal=(k * 3) % 10,
            costume=COS[(k * 5) % len(COS)])
    for k, c in enumerate(REVEALS):
        box, lid = BOXES[k % len(BOXES)]
        add(type="reveal", kind="box", costume=c, name=COSTUMES[c], box=box, lid=lid, pal=(k * 3 + 1) % 10)
    for k, (kind, pal) in enumerate(SATISFY):
        add(type="satisfy", kind=kind, pal=pal, costume="zibo_yeni")
    for k, (title, tips, icons) in enumerate(TIPS):
        add(type="tip", kind="tips", title=title, tips=tips, icons=icons, pal=(k * 3 + 2) % 10, costume=COS[(k * 3 + 1) % len(COS)])
    for k, (kind, panels) in enumerate(POV):
        add(type="pov", kind=kind, panels=panels, pal=(k * 3 + 4) % 10)
    for k, (kind, pal) in enumerate(SATISFY_EXTRA):
        add(type="satisfy", kind=kind, pal=pal, costume="zibo_yeni")
    for k, (kind, panels) in enumerate(POV_EXTRA):
        add(type="pov", kind=kind, panels=panels, pal=(k * 3 + 7) % 10)
    for k, (kind, cos, cards) in enumerate(TRAILERS):
        add(type="trailer", kind=kind, cards=cards, costume=cos, pal=0, dark=True)
    return out


def fname(sp):
    return f"zibo_reel_{sp['id']:02d}_{sp['type']}_{sp['kind']}.mp4"


def caption(sp):
    t = sp["type"]
    if t == "quote":
        body = f"“{sp['text']}”\n\nTiny steps, big change. Meet Zibo, your pocket-sized digital buddy for habits, goals and mood."
    elif t == "reveal":
        body = f"{sp['name']} just unlocked! Which look is your favorite?\n\nDress Zibo in 40+ costumes and themes."
    elif t == "satisfy":
        body = {"water": "Fill it up. Goal reached.", "coins": "Coins stacking up, one task at a time.",
                "checks": "Checking everything off hits different.", "streak": "Day 1 to day 30. Keep the streak alive.",
                "shelf": "Collect every badge.", "costumes": "Which costume would you pick?"}[sp["kind"]] \
               + "\n\nTrack habits, earn Zibo Coins and unlock rewards."
    elif t == "tip":
        body = f"{sp['title']}:\n" + "\n".join(f"{i + 1}. {x}" for i, x in enumerate(sp["tips"])) \
               + "\n\nTrack them with Zibo, your digital buddy."
    elif t == "trailer":
        body = "Coming soon to your phone... actually, it's already here.\n\nZibo: tiny habits, big change."
    else:
        body = "Tag the friend who needs Zibo.\n\nTiny habits, big change, with your digital buddy."
    return f"{body}\n\n{CTA}\n\n{HASH_BASE} {HASH_TYPE[t]}"


@functools.lru_cache(maxsize=4)
def music(track):
    return sfx.load_music(HERE.parent / TRACKS[track]["file"], FF)


def fx(e, tr):
    s, a, t = e["s"], e["a"], e["t"]
    if s == "pop":
        return sfx.pop(a.get("p", 900))
    if s == "blop":
        return sfx.blop(a.get("p", 420), a.get("d", 0.13))
    if s == "tick":
        return sfx.tick(a.get("p", 1500))
    if s == "thud":
        return sfx.thud(a.get("d", 0.22), a.get("p", 130))
    if s == "boing":
        return sfx.boing(a.get("d", 0.45), a.get("p", 260))
    if s == "whoosh":
        return sfx.whoosh(a.get("d", 0.6), a.get("lo", 300), a.get("hi", 3800), seed=int(t * 10) % 97)
    if s == "coin":
        return sfx.coin()
    if s == "bell":
        return sfx.bell(a.get("f", 880) * tr["key"])
    if s == "sparkle":
        return sfx.sparkle(0.5, int(t * 10) % 13 + 1)
    if s == "chime":
        return sfx.chime(tr["chime"])
    if s == "party":
        return sfx.party(seed=int(t * 10) % 29 + 1)
    if s == "womp":
        return sfx.womp()
    raise ValueError(s)


def mix(sp, events, dur, path):
    tr = TRACKS[sp["track"]]
    song = music(sp["track"])
    start = int(sfx.SR * (tr["d0"] + sp["startBar"] * 240 / tr["bpm"]))
    n = int(sfx.SR * (dur + 0.5))
    seg = np.zeros((n, 2))
    part = song[start:start + n]
    seg[:len(part)] = part
    env = np.full(n, 0.35 if sp["type"] == "satisfy" else 0.85)
    if sp["type"] == "trailer":   # müzik karakter sürprizine kadar kısık, sonra yükselir
        tm = next((e["t"] for e in events if e["s"] == "mark"), 0.0)
        i0 = int(sfx.SR * tm)
        ramp = int(sfx.SR * 0.4)
        env[:i0] = 0.16
        env[i0:i0 + ramp] = np.linspace(0.16, 0.9, ramp)
        env[i0 + ramp:] = 0.9
    seg *= env[:, None]
    f = int(sfx.SR * 0.5)
    e = int(sfx.SR * dur)
    seg[e - f:e] *= np.linspace(1, 0, f)[:, None]
    seg[e:] = 0
    T = sfx.Track(dur)
    for ev in events:
        if ev["s"] != "mark":
            T.add(ev["t"], fx(ev, tr), ev["g"])
    T.write(path, music=seg, sfx_gain=1.0)


def page_url(sp):
    return (HERE / "index.html").resolve().as_uri() + "?f=v&cap=1&spec=" + urllib.parse.quote(json.dumps(sp, ensure_ascii=False))


def render_one(sp, stills=None):
    from playwright.sync_api import sync_playwright
    OUT.mkdir(exist_ok=True)
    with sync_playwright() as p:
        br = p.chromium.launch(channel="chrome", headless=True)
        pg = br.new_page(viewport={"width": 1080, "height": 1920})
        pg.goto(page_url(sp))
        pg.wait_for_function("window.READY === true", timeout=90000)
        dur = pg.evaluate("window.DURATION")
        events = pg.evaluate("window.EVENTS")
        if stills is not None:
            d = OUT / "stills"
            d.mkdir(exist_ok=True)
            for frac in stills:
                pg.evaluate(f"seek({dur * frac})")
                pg.screenshot(path=str(d / f"{sp['id']:02d}_{int(frac * 100):03d}.png"))
            br.close()
            return sp["id"]
        wav = OUT / f"_{sp['id']:02d}.wav"
        mix(sp, events, dur, wav)
        target = OUT / fname(sp)
        ff = subprocess.Popen([FF, "-y", "-loglevel", "error", "-f", "image2pipe", "-framerate", str(FPS), "-c:v", "mjpeg", "-i", "-",
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
    return sp["id"], round(dur, 1), target.stat().st_size


def cmd_stills(types):
    from PIL import Image
    chosen = {}
    for sp in specs():
        if (not types or sp["type"] in types) and (sp["type"], sp["kind"]) not in chosen:
            chosen[(sp["type"], sp["kind"])] = sp
    with ProcessPoolExecutor(max_workers=3) as ex:
        list(ex.map(functools.partial(render_one, stills=[0.12, 0.3, 0.5, 0.68, 0.85, 0.97]), chosen.values()))
    for sp in chosen.values():
        fs = sorted((OUT / "stills").glob(f"{sp['id']:02d}_*.png"))
        sh = Image.new("RGB", (len(fs) * 270, 480))
        for i, f in enumerate(fs):
            sh.paste(Image.open(f).convert("RGB").resize((270, 480)), (i * 270, 0))
        sh.save(OUT / "stills" / f"sheet_{sp['id']:02d}_{sp['type']}_{sp['kind']}.png")
        print("sheet", sp["id"], sp["type"], sp["kind"], sp["track"], sp["bars"], "ölçü", sp["startBar"])


def cmd_render(workers, only):
    todo = [s for s in specs() if not only or s["id"] in only]
    print(len(todo), "video,", workers, "işçi", flush=True)
    with ProcessPoolExecutor(max_workers=workers) as ex:
        for r in ex.map(render_one, todo):
            print("OK", r, flush=True)


PAL_NAME = ["golden-yellow", "sky-blue", "purple", "pink", "green", "orange", "royal-blue", "cream", "teal", "coral"]
APP_FACTS = (
    "APP FACTS (true, use only these): Zibo is a pocket-sized digital buddy app for Android (Google Play only, free to download). "
    "It helps people build habits and track goals, water, gratitude, mood, dreams, money and focus time. Completing things earns "
    "Zibo Coins, which unlock 40+ costumes and themes for the Zibo character. The app also has badges, daily streaks with "
    "Streak Freeze, and a Game Hall with 7 mini games."
)
RULES = (
    "CAPTION TASK: Write one Instagram Reels caption in English for this video. 1-3 short, warm, playful sentences that fit the "
    "video (do not just repeat the on-screen text), then a call to action such as \"Free on Google Play. Link in bio!\", then 8-12 "
    "relevant hashtags (always include #zibo). Friendly, never pushy. RULES: no medical, health or income claims; no fake reviews "
    "or user numbers; do not mention prices or iOS; do not invent app features beyond APP FACTS; at most 2 emojis; "
    "output only the caption text."
)
END_CARD = "Ends with the app icon, the Zibo logo, \"Free on Google Play\" and a \"LINK IN BIO\" button."


def describe(sp):
    t, k = sp["type"], sp["kind"]
    cos = COSTUMES.get(sp.get("costume", ""), "the classic Zibo")
    col = PAL_NAME[sp["pal"] % 10]
    sec = round(sp["bars"] * 240 / sp["bpm"])
    if t == "quote":
        what = (f"Zibo (wearing the {cos} look) drops in on a {col} sunburst background. A motivational quote appears word by word: "
                f"\"{sp['text']}\" A small label at the top says \"{sp['label']}\". " + END_CARD)
        text = f"Quote: \"{sp['text']}\"; label: {sp['label']}"
        mood = "warm, encouraging, calm-upbeat"
        angle = "React to the quote in Zibo's friendly voice; invite viewers to save it or share it with a friend who needs it."
    elif t == "reveal":
        what = (f"A red gift box drops in on a {col} sunburst background and asks \"What's inside?\". It shakes on four beats, bursts "
                f"with a white flash and reveals {sp['name']} with the label \"NEW LOOK UNLOCKED!\". It then asks \"Which look is "
                f"your favorite?\". " + END_CARD)
        text = f"NEW LOOK UNLOCKED!; {sp['name']}; Which look is your favorite?"
        mood = "exciting, playful, collectible-reveal energy"
        angle = "Ask viewers which costume they like best (comment bait); mention there are 40+ costumes and themes to unlock."
    elif t == "satisfy":
        what = {
            "water": "A glass slowly fills with water up to 2000 ml with soft bubble sounds, then a water-hero badge pops up with \"GOAL REACHED!\".",
            "coins": "Zibo Coins drop one by one into a growing pile while a counter rises (+5 ZC per coin), with a clink for each coin.",
            "checks": "A to-do list of 8 daily habits (drink water, read 10 pages, walk 20 min, stretch, gratitude note, tidy desk, plan tomorrow, sleep early) gets checked off one per beat until the counter reads 8 / 8.",
            "streak": "A big day counter runs from 1 to 30 while four streak badges (day 7, 14, 21 and 30) pop in along the bottom.",
            "shelf": "Nine achievement badges (water, gratitude, mood, dreams, savings, streak, willpower, first step, balance) drop one by one onto three shelves.",
            "costumes": "A fashion-show loop: a different Zibo costume pops onto a spotlight on every beat (king, astronaut, pirate, samurai, punk and more)."}[k]
        what = f"Oddly satisfying, wordless loop on a {col} sunburst background. " + what + " " + END_CARD
        text = "Almost no text (only counters and labels inside the scene)"
        mood = "satisfying, ASMR-like, soft sound effects over quiet music"
        angle = "Keep it very short and sensory (for example how satisfying it is); invite viewers to watch until the end or save it."
    elif t == "tip":
        tips = "; ".join(f"{i + 1}) {x}" for i, x in enumerate(sp["tips"]))
        what = (f"Title \"{sp['title']}\" on a {col} sunburst background. Three tip cards slide in one after another and each gets a "
                f"checkmark on the beat: {tips}. Zibo (in the {cos} look) stands at the bottom. " + END_CARD)
        text = f"Title: {sp['title']}; tips: {tips}"
        mood = "helpful, friendly, educational-but-light"
        angle = "Frame them as tiny, easy habits; invite viewers to save the tips or try one today. Do not add health claims."
    elif t == "trailer":
        seq = " / ".join(("[Zibo appears: " + COSTUMES.get(c["z"], "Zibo") + "]") if c.get("z") else " ".join(c["t"]) for c in sp["cards"])
        what = ("A parody of a dramatic movie trailer on a dark, cinematic background with letterbox bars, film grain and a light flare. "
                "Big title cards slam in on deep bass hits, the music is quiet until the character reveal and then swells. "
                f"Sequence: {seq}. " + END_CARD)
        text = "Title cards: " + seq
        mood = "dramatic parody, funny because the stakes are tiny (habits, water, coins), cinematic bass hits"
        angle = "Write it like a deadpan movie-trailer tagline with a wink; keep it short; invite viewers to watch until the reveal."
    else:
        pan = " -> ".join(p["t"] + (f" ({p['s']})" if p.get("s") else "") for p in sp["panels"])
        what = (f"A funny, relatable 'POV' skit on a {col} sunburst background: short text panels change on the beat while Zibo reacts "
                f"with a different pose or costume each time. Panels, in order: {pan} | " + END_CARD)
        text = f"Panels: {pan}"
        mood = "funny, relatable, quick cuts with cartoon sound effects"
        angle = "Write it like a relatable joke from Zibo's point of view; invite viewers to tag a friend who does this."
    return (f"VIDEO: {fname(sp)} ({sec} seconds, vertical 9:16, cartoon-sticker style, no voice-over, music plus cartoon sound effects)\n"
            f"WHAT HAPPENS: {what}\n"
            f"ON-SCREEN TEXT: {text}\n"
            f"MOOD: {mood}\n"
            f"CAPTION ANGLE: {angle}\n\n{APP_FACTS}\n\n{RULES}\n")


def cmd_pack():
    sp_all = specs()
    with (OUT / "captions_fallback.csv").open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["file", "type", "caption"])
        for sp in sp_all:
            w.writerow([fname(sp), sp["type"], caption(sp)])
    for sp in sp_all:
        (OUT / fname(sp).replace(".mp4", ".txt")).write_text(describe(sp), encoding="utf-8")
    (OUT / "README.txt").write_text(
        "Zibo Reels paketi - 46 video, 1080x1920 (9:16), H.264 + AAC, 10-15 sn, Ingilizce.\n"
        "videos/ icinde her videonun YANINDA ayni adla bir .txt vardir: videoyu anlatan, Claude API'ye girdi olarak verilecek\n"
        "prompt dosyasi (icinde sahne aciklamasi, ekran yazilari, uygulama bilgileri ve aciklama yazma kurallari bulunur).\n"
        "captions_fallback.csv: API calismazsa yedek olarak kullanabilecegin hazir aciklamalar (UTF-8).\n"
        "Onerilen siralama: turleri karistirarak gunde 1-2 video. Ayni videoyu iki kez paylasma.\n", encoding="utf-8")
    zp = HERE / "Zibo_Reels_Pack.zip"
    with zipfile.ZipFile(zp, "w", zipfile.ZIP_STORED) as z:
        for sp in sp_all:
            z.write(OUT / fname(sp), "videos/" + fname(sp))
            z.write(OUT / fname(sp).replace(".mp4", ".txt"), "videos/" + fname(sp).replace(".mp4", ".txt"))
        z.write(OUT / "captions_fallback.csv", "captions_fallback.csv")
        z.write(OUT / "README.txt", "README.txt")
    print(zp, round(zp.stat().st_size / 1e6, 1), "MB")


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "list":
        for s in specs():
            print(s["id"], s["type"], s["kind"], s["track"], f"{s['bars']} ölçü ≈{s['bars'] * 240 / s['bpm']:.1f}s", "başlangıç ölçü", s["startBar"])
    elif cmd == "stills":
        cmd_stills(sys.argv[2:])
    elif cmd == "render":
        w = int(sys.argv[sys.argv.index("--workers") + 1]) if "--workers" in sys.argv else 4
        only = {int(x) for x in sys.argv[sys.argv.index("--only") + 1].split(",")} if "--only" in sys.argv else None
        cmd_render(w, only)
    elif cmd == "pack":
        cmd_pack()
