// Zibo tanıtım videoları — ortak yardımcılar (v02 ve sonrası).
// Sayfa sözleşmesi (bkz. render.py): ?f=v|h biçim, ?l=tr|es|en dil, ?cap kare yakalama.
// Her video `boot(süre, seekFn)` çağırır; animasyon YALNIZCA seekFn(t)'nin çıktısıdır.
const Q=new URLSearchParams(location.search);
const V=Q.get('f')!=='h';
const W=V?1080:1920,H=V?1920:1080;
const LANG=Q.get('l')||'tr';
const IMG='../../dijital_kanka/assets/images/';
const stage=document.getElementById('stage');
stage.style.width=W+'px';stage.style.height=H+'px';

const clamp=(x,a=0,b=1)=>Math.min(b,Math.max(a,x));
const prog=(t,a,d)=>clamp((t-a)/d);
const lerp=(a,b,p)=>a+(b-a)*p;
const eOut=x=>1-Math.pow(1-x,3);
const eInOut=x=>x<.5?4*x*x*x:1-Math.pow(-2*x+2,3)/2;
const eBack=x=>{const c1=1.70158,c3=c1+1;return 1+c3*Math.pow(x-1,3)+c1*Math.pow(x-1,2)};
function eBounce(x){const n=7.5625,d=2.75;
  if(x<1/d)return n*x*x;if(x<2/d)return n*(x-=1.5/d)*x+.75;
  if(x<2.5/d)return n*(x-=2.25/d)*x+.9375;return n*(x-=2.625/d)*x+.984375}
// Giriş-çıkış ölçeği: tin'de "pop" ile gelir, sahnenin son 0,3 sn'sinde küçülerek gider.
// Sahne dışındaki her t için 0 döndürür → görünürlük ayrıca yönetilmez.
const io=(lt,tin,dur)=>{const a=prog(lt,tin,.4),b=prog(lt,dur-.3,.3);return lt<0?0:(a<=0?0:eBack(a))*(1-b*b)};
function rng(seed){let s=seed;return()=>{s=(s*1664525+1013904223)%4294967296;return s/4294967296}}
const hex=c=>[1,3,5].map(i=>parseInt(c.slice(i,i+2),16));
const mix=(a,b,p)=>{const x=hex(a),y=hex(b);return`rgb(${x.map((v,i)=>Math.round(lerp(v,y[i],p))).join(',')})`};

function mk(parent,tag,cls,html){const e=document.createElement(tag);if(cls)e.className=cls;
  if(html!=null)e.innerHTML=html;parent.appendChild(e);return e}
function img(parent,name,h,w){const e=mk(parent,'img','o');e.src=IMG+encodeURI(name);
  if(h)e.style.height=h+'px';if(w)e.style.width=w+'px';return e}
function put(el,x,y,s=1,r=0,o=1,sx=1){
  el.style.transform=`translate(${x}px,${y}px) translate(-50%,-50%) rotate(${r}deg) scale(${s*sx},${s})`;
  el.style.opacity=o}
// Başlık: satırlar dizisi; *kelime* → altın renk. Her kelime ayrı ayrı "pop" eder.
function headline(parent,lines,size){
  const el=mk(parent,'div','o hl');el.style.fontSize=size+'px';const words=[];
  for(const line of lines){const row=mk(el,'div');
    line.split(' ').forEach((w,i)=>{const g=w.startsWith('*');
      const sp=mk(row,'span',g?'g':'',(i?'&nbsp;':'')+w.replace(/\*/g,''));words.push(sp)})}
  return{el,words}}
function popWords(h,lt,t0,step=.15){h.words.forEach((w,i)=>{const p=prog(lt,t0+i*step,.38);
  w.style.transform=`scale(${p<=0?0:eBack(p)}) rotate(${lerp(-8,0,eOut(p))}deg)`})}
// Çeviri uzun gelirse yazıyı kutusuna sığdır (fontlar yüklendikten sonra ölçülür).
const FITS=[];const fit=(el,maxW)=>(FITS.push([el,maxW]),el);

function boot(duration,seekFn){
  window.DURATION=duration;window.seek=seekFn;
  Promise.all([document.fonts.load('800 40px Baloo2'),document.fonts.load('900 40px Nunito'),
    ...[...document.images].map(im=>im.decode().catch(()=>{}))]).then(()=>{
    FITS.forEach(([el,maxW])=>{const w=el.offsetWidth;
      if(w>maxW)el.style.fontSize=parseFloat(getComputedStyle(el).fontSize)*maxW/w+'px'});
    seekFn(0);window.READY=true;
    if(!Q.has('cap')){ // canlı önizleme: pencereye sığdır + döngü
      const k=Math.min(innerWidth/W,innerHeight/H);stage.style.transformOrigin='0 0';stage.style.transform=`scale(${k})`;
      const t0=performance.now();(function loop(){seekFn(((performance.now()-t0)/1000)%(duration+.8));requestAnimationFrame(loop)})()}})}
