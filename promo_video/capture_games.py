"""Oyun Salonu oyunlarından GERÇEK oynanış karelerini yakalar (tanıtım videoları için).

Kullanım (repo kökünden):  python promo_video/capture_games.py v03 [tr es en]
Çıktı: promo_video/<video>/clips/<dil>/<oyun>/000.jpg … (720×1280, 30 fps)

Nasıl çalışır — uygulamanın oyun dosyalarına DOKUNMADAN:
  * `dijital_kanka/assets` yerel bir HTTP sunucusundan servis edilir; oyunun index.html'i
    yolda yamalanır: kapanış `})();`'ünden önce `window.__eval` eklenir → oyunun kendi
    değişkenlerine (durum, bloklar, yılan…) dışarıdan erişilir.
  * Sayfaya sanal saat enjekte edilir (performance.now / rAF / setTimeout / Date.now /
    Math.random + CSS animasyonları) → oyun gerçek zamanla değil `__step(ms)` ile ilerler;
    kareler takılmasız ve her çalıştırmada birebir aynı.
  * Her oyunu küçük bir "bot" oynar (BOTS) — önce ekran dışı ısınma (oyun ilerlesin),
    sonra kare kare yakalama.
"""
import functools
import http.server
import sys
import threading
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).parent
ASSETS = ROOT.parent / "dijital_kanka" / "assets"
FPS = 30
CAPTURE_SECONDS = 2.4

SHIM = r"""
(() => {
  let now = 0, raf = [], timers = [], nid = 1, seed = 20260930;
  Math.random = () => { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed / 4294967296; };
  performance.now = () => now;
  Date.now = () => 1790000000000 + now;
  window.requestAnimationFrame = f => { raf.push(f); return nid++; };
  window.cancelAnimationFrame = () => {};
  window.setTimeout = (f, ms = 0, ...a) => { const id = nid++; timers.push({ id, t: now + ms, f: () => f(...a) }); return id; };
  window.setInterval = (f, ms) => { const id = nid++; timers.push({ id, t: now + ms, f, iv: ms }); return id; };
  window.clearTimeout = window.clearInterval = id => { timers = timers.filter(x => x.id !== id); };
  window.__step = ms => {
    now += ms;
    for (;;) {
      const due = timers.filter(x => x.t <= now).sort((a, b) => a.t - b.t)[0];
      if (!due) break;
      if (due.iv) due.t += due.iv; else timers = timers.filter(x => x !== due);
      due.f();
    }
    const cbs = raf; raf = []; cbs.forEach(f => f(now));
    document.getAnimations().forEach(a => {
      if (!a.__v) { a.__v = true; a.pause(); }
      a.currentTime = (a.currentTime || 0) + ms;
      const end = a.effect.getComputedTiming().endTime;
      if (isFinite(end) && a.currentTime >= end) a.finish();
    });
  };
  // Bir video karesi = 2 alt adım (her biri 1/60 sn); her alt adımdan önce bot oynar.
  window.__frame = bot => { for (let i = 0; i < 2; i++) { if (bot) window.__eval(bot); window.__step(1000 / 60); } };
})();
"""

# Botlar oyunun KENDİ kapanışı içinde çalışır (__eval) → oyun değişkenlerini doğrudan okur.
BOTS = {
    # Kule: blok hizalanınca bırak; her 4 bloktan biri bilerek biraz kaçık (kesilme de görünsün).
    "kule": """(function(){if(state!=='play'||!cur)return;var top=stack[stack.length-1];
      var off=(stack.length%4===3)?-13*cur.dir:0;if(Math.abs(cur.x-top.x-off)<=3.3)drop();})()""",
    # Hafıza: çoğunlukla doğru çifti açar, her 3 hamlede bir bilerek yanlış.
    "hafiza": """(function(){if(lock)return;if(performance.now()-(window.__last||0)<300)return;
      var un=cards.filter(function(c){return !c.done&&!c.up});if(!un.length)return;window.__last=performance.now();
      if(open.length===1){var a=open[0];window.__n=(window.__n||0)+1;
        var o=un.filter(function(c){return c.id!==a.id})[0],m=un.filter(function(c){return c.id===a.id})[0];
        flip(window.__n%3===0&&o?o:(m||un[0]));return}
      flip(un[0]);})()""",
    # 2048: aşağı-sol öncelikli klasik strateji.
    "2048": """(function(){if(lock||!playing)return;if(performance.now()-(window.__last||0)<240)return;
      var order=['down','left','right','up'];for(var i=0;i<4;i++){move(order[i]);if(lock){window.__last=performance.now();return}}})()""",
    # Coin Yakala: en alttaki coine git, yakındaki bombadan kaç.
    "yakala": """(function(){if(state!=='play')return;var cy=zibo.y-30,best=null;
      items.forEach(function(it){if(it.kind!=='bomb'&&!it.gone&&it.y<cy&&(!best||it.y>best.y))best=it;});
      var tx=best?best.x:W/2;
      items.forEach(function(it){if(it.kind==='bomb'&&it.y>cy-190&&it.y<cy+30&&Math.abs(it.x-tx)<56)tx=it.x+(tx>=it.x?1:-1)*64;});
      targetX=tx;})()""",
    # Tren (yılan): en yakın coine en kısa yol (BFS).
    "tren": """(function(){if(state!=='play'||queue.length)return;var h=snake[0],blk={},tg={},ds=['up','down','left','right'],q=[],seen={};
      snake.forEach(function(p){blk[p.x+','+p.y]=1});rocks.forEach(function(p){blk[p.x+','+p.y]=1});
      items.forEach(function(p){tg[p.x+','+p.y]=1});
      ds.forEach(function(d){if(d===OPP[dir])return;var x=h.x+VEC[d][0],y=h.y+VEC[d][1],k=x+','+y;
        if(x<0||y<0||x>=COLS||y>=ROWS||blk[k])return;seen[k]=1;q.push([x,y,d])});
      var pick=q.length?q[0][2]:null;
      for(var i=0;i<q.length;i++){var c=q[i];if(tg[c[0]+','+c[1]]){pick=c[2];break}
        ds.forEach(function(d){var x=c[0]+VEC[d][0],y=c[1]+VEC[d][1],k=x+','+y;
          if(x<0||y<0||x>=COLS||y>=ROWS||blk[k]||seen[k])return;seen[k]=1;q.push([x,y,c[2]])})}
      if(pick&&pick!==dir)turn(pick);})()""",
    # Zıpla: sıradaki sütunun boşluğunun biraz altına düşünce kanat çırp.
    "zipla": """(function(){if(state!=='play')return;var p=null;
      pipes.forEach(function(q){if(!p&&q.x+64>z.x-z.r)p=q;});
      var ty=p?p.gy+p.g*0.17:H*0.45;if(z.y>ty&&z.vy>-120)flap();})()""",
    # Tuğla: 40 açıyı oyunun kendi fizik adımıyla dener (durumu kopyalayıp geri yükler),
    # en çok hasar + top halkası getiren açıyla ateş eder.
    "tugla": """(function(){if(state!=='aim'||!bricks.length)return;
      var sb=JSON.stringify(bricks),sr=JSON.stringify(rings),sp=pending,sbr=broken,sn=nextX,pl=pops.length,best=-1.57,bs=-1;
      for(var k=0;k<40;k++){var a=-0.2-k*(Math.PI-0.4)/39,hp0=0,hp1=0;
        bricks=JSON.parse(sb);rings=JSON.parse(sr);pending=sp;broken=sbr;
        bricks.forEach(function(b){hp0+=b.hp});
        for(var n=0;n<count;n++){var ball={x:launchX,y:FLOOR-R,vx:Math.cos(a)*SPEED,vy:Math.sin(a)*SPEED};
          for(var i=0;i<2500&&!ball.done;i++)step(ball,0.004);}
        bricks.forEach(function(b){hp1+=b.hp});
        var sc=(hp0-hp1)+(pending-sp)*6+(broken-sbr)*2;if(sc>bs){bs=sc;best=a;}}
      bricks=JSON.parse(sb);rings=JSON.parse(sr);pending=sp;broken=sbr;nextX=sn;pops.length=pl;
      aim=clampAim(best);fire();})()""",
}
START = {g: "document.getElementById('startBtn').click()" for g in BOTS}
START["hafiza"] = "document.querySelectorAll('#levels button')[1].click()"
# Isınma: sabit süre (sn) veya "şu koşul sağlanana kadar" (JS ifadesi, en çok 90 sn)
WARMUP = {"kule": 10, "hafiza": "!lock&&found>=1", "2048": 16, "yakala": 14, "tren": 16, "zipla": 6,
          "tugla": "state==='fly'&&turnNo>=9&&turnT>0.1"}
# Yakalama bitince oyunun hâlâ oynanıyor olduğunu doğrulayan ifade
ALIVE = {"kule": "state==='play'", "hafiza": "!outcome", "2048": "playing&&document.getElementById('stuck').hidden",
         "yakala": "state==='play'", "tren": "state==='play'", "zipla": "state==='play'", "tugla": "state==='fly'||state==='aim'"}
INFO = {"kule": "floors()", "hafiza": "found", "2048": "score+'/'+top", "yakala": "score+' can '+lives", "tren": "eaten",
        "zipla": "pillars+'/'+collected", "tugla": "'tur '+turnNo+' top '+count+' kırık '+broken"}


class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_GET(self):
        p = self.path.split("?")[0]
        if p.startswith("/games/") and p.endswith("/index.html"):
            html = (ASSETS / p.lstrip("/")).read_text(encoding="utf-8")
            i = html.rindex("})();")
            body = (html[:i] + "window.__eval=function(__s){return eval(__s)};\n" + html[i:]).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()


def main():
    video = sys.argv[1]
    langs = sys.argv[2:] or ["tr"]
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Handler, directory=str(ASSETS)))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{srv.server_address[1]}/games"
    frames = int(CAPTURE_SECONDS * FPS)
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        for lang in langs:
            ctx = browser.new_context(viewport={"width": 360, "height": 640}, device_scale_factor=2, locale=lang)
            ctx.add_init_script(SHIM)
            for game, bot in BOTS.items():
                page = ctx.new_page()
                page.goto(f"{base}/{game}/index.html")
                time.sleep(0.8)  # görseller/fontlar gerçek zamanda yüklenir
                page.evaluate("__step(100)")
                page.evaluate(START[game])
                page.evaluate("for(let i=0;i<12;i++)__step(1000/60)")
                warm = WARMUP[game]
                if isinstance(warm, str):
                    ok = page.evaluate(
                        "([bot,cond])=>{for(let i=0;i<90*30;i++){if(__eval(cond))return true;__frame(bot)}return false}", [bot, warm])
                    if not ok:
                        print(f"  UYARI {game}: ısınma koşulu sağlanmadı ({warm})")
                else:
                    page.evaluate("([bot,n])=>{for(let i=0;i<n;i++)__frame(bot)}", [bot, int(warm * FPS)])
                out = ROOT / video / "clips" / lang / game
                out.mkdir(parents=True, exist_ok=True)
                for i in range(frames):
                    page.evaluate("bot=>__frame(bot)", bot)
                    page.screenshot(path=str(out / f"{i:03d}.jpg"), type="jpeg", quality=88)
                alive = page.evaluate("c=>__eval(c)", ALIVE[game])
                info = page.evaluate("c=>String(__eval(c))", INFO[game])
                print(f"{lang} {game}: {frames} kare, oyun sürüyor={alive}, durum: {info}", flush=True)
                page.close()
            ctx.close()
        browser.close()
    srv.shutdown()


if __name__ == "__main__":
    main()
