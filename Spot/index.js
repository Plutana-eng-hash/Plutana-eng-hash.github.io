const CLIENT_ID='c82434c3ef7743a3bafe4372f6c9dfe3';
const REDIRECT_URI=window.location.origin+window.location.pathname;
const SCOPES=[
  'streaming','user-read-email','user-read-private',
  'playlist-read-private','playlist-read-collaborative',
  'playlist-modify-public','playlist-modify-private',
  'user-modify-playback-state','user-read-playback-state'
].join(' ');
const IS_FILE=window.location.protocol==='file:';
const IMG_PROXY='https://images.weserv.nl/?url=';
const CACHE_TTL=5*60*1000;
const SEARCH_TTL=2*60*1000;
const SETTINGS_KEY='sp_clone_settings_v5';
const THEMES_DIR='Themes';
const THEME_VARS=['--bg-base','--bg-elevated','--bg-card','--bg-hover','--text-base','--text-subdued','--brand','--brand-hover'];
const SPICE_KEYS=['main','sidebar','player','card','shadow','text','subtext','selected-row','button','button-active','button-disabled','tab-active','notification','notification-error','misc'];

const ICON_PLAY='<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
const ICON_PAUSE='<svg viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="5" width="3.6" height="14" rx="1"/><rect x="14.4" y="5" width="3.6" height="14" rx="1"/></svg>';
const ICON_NOTE_BIG='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M9 18V6l10-2v12"/><circle cx="6" cy="18" r="2.6"/><circle cx="16" cy="16" r="2.6"/></svg>';
const ICON_NOTE_SMALL='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M9 18V6l10-2v12"/><circle cx="6" cy="18" r="2.6"/><circle cx="16" cy="16" r="2.6"/></svg>';
const ICON_PLUS='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>';
const ICON_CHECK='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>';

const DEFAULT_SETTINGS={
  theme:'',accent:'',useAccent:false,radius:8,sidebarWidth:280,
  density:'normal',showNumbers:true,animations:true,
  bgSource:'theme',bgUrl:'',bgBlur:60,bgOpacity:60,bgDim:55,
  seekStep:10,adMute:true,autoSkipShort:false,shortcuts:true,
  applyRawCss:true,applySpiceVars:true
};

const $=id=>document.getElementById(id);
const loginEl=$('login'),appEl=$('app'),mainEl=$('main'),playlistListEl=$('playlist-list');
const nowCoverEl=$('now-cover'),nowTitleEl=$('now-title'),nowArtistEl=$('now-artist');
const playBtn=$('play-btn'),prevBtn=$('prev-btn'),nextBtn=$('next-btn');
const seekEl=$('seek'),timeCurrentEl=$('time-current'),timeTotalEl=$('time-total'),volumeEl=$('volume');
const toastEl=$('toast'),fxPanel=$('fx-panel'),fxToggle=$('fx-toggle'),fxStatus=$('fx-status');
const pitchSlider=$('pitch-slider'),pitchValueEl=$('pitch-value'),bassSlider=$('bass-slider'),bassValueEl=$('bass-value');
const bgLayer=$('bg-layer'),bgDim=$('bg-dim'),queueDrawer=$('queue-drawer'),queueBody=$('queue-body');
const sidebarEl=$('sidebar'),mobileMenuBtn=$('mobile-menu-btn'),sidebarBackdrop=$('sidebar-backdrop');
const signoutBtn=$('signout-btn'),sidebarAvatar=$('sidebar-avatar'),sidebarUsername=$('sidebar-username');

window.addEventListener('error',e=>{
  console.error('[sc] uncaught error:',e.error||e.message);
});
window.addEventListener('unhandledrejection',e=>{
  console.error('[sc] unhandled rejection:',e.reason);
});

let accessToken=null,tokenExpiresAt=0;
let player=null,deviceId=null,sdkReady=false,appIsShown=false;
let isPaused=true,currentPosition=0,currentDuration=0,seekDragging=false,pollTimer=null;
let userPlaylists=[],activePlaylistId=null,activeTrackUri=null,currentArtUrl=null;
let searchState={query:'',tracks:[],hasMore:false,offset:0,total:0},searchDebounce=null;
let settingsTab='themes',adMuted=false,lastAutoSkipUri=null;
let currentUserId=null,currentUserProfile=null;

let THEMES=[];
let themesStatus={state:'idle',count:0,message:'Not loaded'};

const cache=new Map(),searchCache=new Map(),plMembership=new Map(),membershipLoading=new Set();

let sdkAudioEl=null,bassCtx=null,bassFilter=null,bassHookState='idle',currentPitch=1.0,currentBass=0;

let settings=loadSettings();

function loadSettings(){
  try{return Object.assign({},DEFAULT_SETTINGS,JSON.parse(localStorage.getItem(SETTINGS_KEY)||'{}'));}
  catch(e){return Object.assign({},DEFAULT_SETTINGS);}
}
function saveSettings(){try{localStorage.setItem(SETTINGS_KEY,JSON.stringify(settings));}catch(e){}}

function shade(hex,percent){
  let h=(hex||'#1DB954').replace('#','');
  if(h.length===3)h=h.split('').map(c=>c+c).join('');
  if(h.length!==6)h='1DB954';
  const num=parseInt(h,16);
  let r=(num>>16)&255,g=(num>>8)&255,b=num&255;
  r=Math.min(255,Math.round(r+(255-r)*percent/100));
  g=Math.min(255,Math.round(g+(255-g)*percent/100));
  b=Math.min(255,Math.round(b+(255-b)*percent/100));
  return '#'+[r,g,b].map(v=>v.toString(16).padStart(2,'0')).join('');
}
function hexToRgb(hex){
  let h=(hex||'#000000').replace('#','');
  if(h.length===3)h=h.split('').map(c=>c+c).join('');
  if(h.length!==6)h='000000';
  return `${parseInt(h.slice(0,2),16)||0},${parseInt(h.slice(2,4),16)||0},${parseInt(h.slice(4,6),16)||0}`;
}

function currentTheme(){
  if(!THEMES.length)return null;
  return THEMES.find(x=>x.id===settings.theme)||THEMES[0];
}

function clearThemeVars(){
  const rs=document.documentElement.style;
  THEME_VARS.forEach(v=>rs.removeProperty(v));
  SPICE_KEYS.forEach(k=>{
    rs.removeProperty('--spice-'+k);
    rs.removeProperty('--spice-rgb-'+k);
  });
  const old=document.getElementById('user-theme-css');
  if(old)old.remove();
}

function applySettings(){
  const t=currentTheme();
  const rs=document.documentElement.style;
  if(t){
    rs.setProperty('--bg-base',t.bg);
    rs.setProperty('--bg-elevated',t.elevated);
    rs.setProperty('--bg-card',t.card);
    rs.setProperty('--bg-hover',t.hover);
    rs.setProperty('--text-base',t.text);
    rs.setProperty('--text-subdued',t.sub);
    const accent=settings.useAccent&&settings.accent?settings.accent:t.brand;
    rs.setProperty('--brand',accent);
    rs.setProperty('--brand-hover',shade(accent,22));
    if(settings.applySpiceVars)applySpiceVars(t);
    else SPICE_KEYS.forEach(k=>{
      rs.removeProperty('--spice-'+k);
      rs.removeProperty('--spice-rgb-'+k);
    });
    applyUserCss(t);
  }else{
    clearThemeVars();
  }
  rs.setProperty('--radius',settings.radius+'px');
  rs.setProperty('--bg-blur',settings.bgBlur+'px');
  rs.setProperty('--bg-alpha',String(settings.bgOpacity/100));
  rs.setProperty('--bg-dim',String(settings.bgDim/100));
  const device=document.body.dataset.device||'desktop';
  if(device==='desktop')rs.setProperty('--sidebar-w',settings.sidebarWidth+'px');
  document.body.classList.toggle('density-compact',settings.density==='compact');
  document.body.classList.toggle('density-comfortable',settings.density==='comfortable');
  document.body.classList.toggle('hide-numbers',!settings.showNumbers);
  document.body.classList.toggle('reduce-motion',!settings.animations);
  applyBackground();
  saveSettings();
}

function applySpiceVars(theme){
  const r=document.documentElement.style;
  const map={
    main:theme.bg,sidebar:theme.elevated,player:theme.elevated,card:theme.card,
    shadow:theme.hover,text:theme.text,subtext:theme.sub,'selected-row':theme.hover,
    button:theme.brand,'button-active':shade(theme.brand,20),'button-disabled':'#7f7f7f',
    'tab-active':theme.brand,notification:theme.brand,'notification-error':'#e22134',misc:theme.brand
  };
  Object.keys(map).forEach(k=>{
    r.setProperty('--spice-'+k,map[k]);
    r.setProperty('--spice-rgb-'+k,hexToRgb(map[k]));
  });
}

function applyUserCss(theme){
  const old=document.getElementById('user-theme-css');
  if(old)old.remove();
  if(!theme||!theme.folderId||!settings.applyRawCss)return;
  if(!theme.hasUserCss)return;
  const link=document.createElement('link');
  link.id='user-theme-css';
  link.rel='stylesheet';
  link.href=THEMES_DIR+'/'+theme.folderId+'/user.css';
  document.head.appendChild(link);
}

function applyBackground(){
  let url=null;
  if(settings.bgSource==='album'&&currentArtUrl)url=proxiedUrl(currentArtUrl);
  else if(settings.bgSource==='custom'&&settings.bgUrl)url=settings.bgUrl.startsWith('data:')?settings.bgUrl:proxiedUrl(settings.bgUrl);
  if(url){bgLayer.style.backgroundImage='url("'+url.replace(/"/g,'%22')+'")';bgLayer.classList.add('on');}
  else{bgLayer.style.backgroundImage='none';bgLayer.classList.remove('on');}
}

function showToast(msg,duration,type){
  toastEl.textContent=msg;
  toastEl.className='toast show'+(type?' '+type:'');
  clearTimeout(toastEl._t);
  toastEl._t=setTimeout(()=>toastEl.classList.remove('show'),duration||3500);
}

function formatTime(ms){if(!ms||ms<0||!isFinite(ms))return '0:00';const s=Math.floor(ms/1000);return Math.floor(s/60)+':'+String(s%60).padStart(2,'0');}
function paintRange(el){const min=+el.min||0,max=+el.max||100;const pct=((+el.value-min)/(max-min))*100;el.style.setProperty('--pct',pct+'%');}

function pickImage(images){
  if(!Array.isArray(images))return null;
  const valid=images.filter(x=>x&&typeof x.url==='string'&&x.url.length);
  if(!valid.length)return null;
  return valid.reduce((a,b)=>((a.width||0)>=(b.width||0)?a:b)).url;
}
function proxiedUrl(url){if(!url)return null;if(url.startsWith('data:'))return url;return IMG_PROXY+encodeURIComponent(url.replace(/^https?:\/\//,''));}

function setImg(container,url,fallbackHtml,lazy){
  container.innerHTML='';
  if(!url){container.innerHTML=fallbackHtml;return;}
  const img=document.createElement('img');
  img.alt='';
  if(lazy)img.loading='lazy';
  img.setAttribute('referrerpolicy','no-referrer');
  img.setAttribute('decoding','async');
  let stage=0;
  img.addEventListener('error',()=>{
    if(stage===0){stage=1;img.src=proxiedUrl(url);}
    else if(container.contains(img)){container.innerHTML=fallbackHtml;}
  });
  img.src=url;container.appendChild(img);
}

function trackImage(t){if(!t)return null;return pickImage(t.album&&t.album.images)||pickImage(t.images);}
function trackArtistText(t){const n=(t.artists||[]).map(a=>a&&a.name).filter(Boolean);if(n.length)return n.join(', ');if(t.show&&t.show.name)return t.show.name;return 'Unknown Artist';}
function playlistTrackCount(p){if(!p)return 0;if(p._actualCount!=null)return p._actualCount;if(p.tracks&&typeof p.tracks.total==='number')return p.tracks.total;if(p.items&&typeof p.items.total==='number')return p.items.total;return 0;}

function canModifyPlaylist(p){
  if(!p)return false;
  if(p.collaborative)return true;
  if(!currentUserId)return true;
  if(p.owner&&p.owner.id===currentUserId)return true;
  if(p.owner&&p.owner.id&&p.owner.id!==currentUserId)return false;
  return true;
}

function cachedFetch(key,fetcher,ttl){
  const e=cache.get(key),t=ttl||CACHE_TTL;
  if(e&&Date.now()-e.ts<t)return Promise.resolve(e.data);
  return fetcher().then(data=>{cache.set(key,{data,ts:Date.now()});return data;});
}
function clearCaches(){cache.clear();searchCache.clear();}
function invalidatePlaylist(id){cache.delete('pl:'+id);cache.delete('pl-tracks:'+id);}

function normalizeHex(v){
  if(!v)return null;
  v=String(v).trim();
  if(!v)return null;
  if(!v.startsWith('#'))v='#'+v;
  if(/^#[0-9a-fA-F]{3}$/.test(v))return '#'+v[1]+v[1]+v[2]+v[2]+v[3]+v[3];
  if(/^#[0-9a-fA-F]{6}$/.test(v))return v.toLowerCase();
  return null;
}

function parseColorIni(text){
  const sections={};
  let current=null;
  for(const rawLine of text.split(/\r?\n/)){
    const line=rawLine.trim();
    if(!line||line.startsWith(';')||line.startsWith('#'))continue;
    if(line.startsWith('[')&&line.endsWith(']')){current=line.slice(1,-1).trim();sections[current]={};continue;}
    const eq=line.indexOf('=');
    if(eq>0&&current){
      const key=line.slice(0,eq).trim();
      let val=line.slice(eq+1).trim();
      const ci=val.indexOf(';');
      if(ci>=0)val=val.slice(0,ci).trim();
      sections[current][key]=val;
    }
  }
  return sections;
}

function buildThemeFromIni(folderId,displayName,sections){
  const sectionNames=Object.keys(sections);
  if(!sectionNames.length)return null;
  const preferred=sectionNames.find(n=>/^(base|default|dark|main|scheme)/i.test(n))||sectionNames[0];
  const s=sections[preferred];
  const lowerKeys={};
  Object.keys(s).forEach(k=>{lowerKeys[k.toLowerCase()]=s[k];});
  const pick=(...keys)=>{
    for(const k of keys){const v=normalizeHex(lowerKeys[k.toLowerCase()]);if(v)return v;}
    return null;
  };
  return {
    id:'file:'+folderId,folderId,name:displayName,
    brand:pick('button','playing','play-button','tab-active','notification','misc')||'#1DB954',
    bg:pick('main','background','base')||'#000000',
    elevated:pick('sidebar','player','top-bar')||'#121212',
    card:pick('card','shadow')||'#181818',
    hover:pick('selected-row','shadow','card')||'#282828',
    text:pick('main-text','text')||'#ffffff',
    sub:pick('subtext','text-subdued')||'#a7a7a7',
    section:preferred,hasUserCss:false
  };
}

async function fetchText(path){
  try{const res=await fetch(path,{cache:'no-store'});if(!res.ok)return null;return await res.text();}catch(e){return null;}
}

async function loadThemeFromFolder(folderId,displayName){
  const [iniText,cssText]=await Promise.all([
    fetchText(THEMES_DIR+'/'+folderId+'/color.ini'),
    fetchText(THEMES_DIR+'/'+folderId+'/user.css')
  ]);
  if(!iniText)return null;
  const sections=parseColorIni(iniText);
  const theme=buildThemeFromIni(folderId,displayName||folderId,sections);
  if(!theme)return null;
  theme.hasUserCss=!!cssText;
  return theme;
}

async function loadFileBasedThemes(){
  themesStatus={state:'loading',count:0,message:'Scanning '+THEMES_DIR+' folder…'};
  const fileThemes=[];
  if(IS_FILE){themesStatus={state:'error',count:0,message:'Cannot read folder from file://'};return fileThemes;}
  const manifestText=await fetchText(THEMES_DIR+'/manifest.json');
  if(!manifestText){themesStatus={state:'warn',count:0,message:'No manifest.json in '+THEMES_DIR+'/. App runs with default styles.'};return fileThemes;}
  let list=[];
  try{
    const parsed=JSON.parse(manifestText);
    const arr=Array.isArray(parsed)?parsed:(parsed.themes||[]);
    list=arr.map(x=>typeof x==='string'?{id:x,name:x}:{id:x.id||x.folder||x.name,name:x.name||x.id}).filter(x=>x&&x.id);
  }catch(e){themesStatus={state:'error',count:0,message:'manifest.json is not valid JSON.'};return fileThemes;}
  if(!list.length){themesStatus={state:'warn',count:0,message:'manifest.json contains no entries. App runs with default styles.'};return fileThemes;}
  const results=await Promise.all(list.map(async(item)=>loadThemeFromFolder(item.id,item.name||item.id)));
  results.forEach(t=>{if(t)fileThemes.push(t);});
  if(fileThemes.length)themesStatus={state:'ok',count:fileThemes.length,message:fileThemes.length+' of '+list.length+' theme'+(fileThemes.length===1?'':'s')+' loaded from '+THEMES_DIR+'/'};
  else themesStatus={state:'error',count:0,message:'manifest.json lists '+list.length+' theme'+(list.length===1?'':'s')+' but none could be loaded. Check that each folder has a color.ini.'};
  return fileThemes;
}

async function refreshThemes(){
  const fileThemes=await loadFileBasedThemes();
  THEMES=fileThemes;
  if(THEMES.length){
    if(!THEMES.find(t=>t.id===settings.theme)){settings.theme=THEMES[0].id;saveSettings();}
  }else{
    settings.theme='';saveSettings();
  }
  applySettings();
  if(settingsTab==='themes'&&appEl.style.display!=='none')drawSettings();
  return fileThemes.length;
}

function detectDevice(){
  const w=window.innerWidth,h=window.innerHeight;
  const isTouch=matchMedia('(pointer: coarse)').matches||'ontouchstart' in window;
  const device=w<768?'mobile':w<1024?'tablet':'desktop';
  document.body.dataset.device=device;
  document.body.classList.toggle('is-touch',isTouch);
  document.body.classList.toggle('is-landscape',w>h);
  document.documentElement.style.setProperty('--app-h',h+'px');
  if(device!=='mobile')closeSidebar();
  const rs=document.documentElement.style;
  if(device==='desktop')rs.setProperty('--sidebar-w',settings.sidebarWidth+'px');
  else if(device==='tablet')rs.setProperty('--sidebar-w','76px');
  else rs.setProperty('--sidebar-w','0px');
}

function openSidebar(){if(document.body.dataset.device!=='mobile')return;sidebarEl.classList.add('open');sidebarBackdrop.classList.add('show');}
function closeSidebar(){sidebarEl.classList.remove('open');sidebarBackdrop.classList.remove('show');}
function toggleSidebar(){if(sidebarEl.classList.contains('open'))closeSidebar();else openSidebar();}

function randomString(n){
  const c='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const b=crypto.getRandomValues(new Uint8Array(n));
  return Array.from(b,x=>c[x%c.length]).join('');
}
const sha256=s=>crypto.subtle.digest('SHA-256',new TextEncoder().encode(s));
const base64url=buf=>btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/=/g,'').replace(/\+/g,'-').replace(/\//g,'_');

async function startLogin(){
  if(IS_FILE){document.getElementById('file-warning').style.display='block';return;}
  if(!crypto.subtle){
    showToast('This app needs HTTPS (or localhost) — crypto.subtle is unavailable on this connection.',8000);
    return;
  }
  const verifier=randomString(128);
  sessionStorage.setItem('pkce_verifier',verifier);
  const params=new URLSearchParams({
    client_id:CLIENT_ID,response_type:'code',redirect_uri:REDIRECT_URI,scope:SCOPES,
    show_dialog:'true',code_challenge_method:'S256',code_challenge:base64url(await sha256(verifier))
  });
  window.location.href='https://accounts.spotify.com/authorize?'+params;
}

function storeToken(data){
  accessToken=data.access_token;
  tokenExpiresAt=Date.now()+data.expires_in*1000-60000;
  if(data.refresh_token)localStorage.setItem('spotify_refresh_token',data.refresh_token);
}

async function exchangeCode(code){
  const res=await fetch('https://accounts.spotify.com/api/token',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({client_id:CLIENT_ID,grant_type:'authorization_code',code,redirect_uri:REDIRECT_URI,code_verifier:sessionStorage.getItem('pkce_verifier')})});
  if(!res.ok)throw new Error('Token exchange failed');
  storeToken(await res.json());
}

async function refreshAccessToken(){
  const rt=localStorage.getItem('spotify_refresh_token');
  if(!rt)return null;
  const res=await fetch('https://accounts.spotify.com/api/token',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({client_id:CLIENT_ID,grant_type:'refresh_token',refresh_token:rt})});
  if(!res.ok)return null;
  storeToken(await res.json());
  return accessToken;
}

async function getValidToken(){if(accessToken&&Date.now()<tokenExpiresAt)return accessToken;return await refreshAccessToken();}

async function apiFetch(url,options){
  options=options||{};
  const token=await getValidToken();
  if(!token)throw new Error('Not signed in');
  const baseHeaders=Object.assign({},options.headers||{},{Authorization:'Bearer '+token});
  let res=await fetch(url,Object.assign({},options,{headers:baseHeaders}));
  if(res.status===401){
    const fresh=await refreshAccessToken();
    if(!fresh)throw new Error('Session expired. Please sign in again.');
    res=await fetch(url,Object.assign({},options,{headers:Object.assign({},baseHeaders,{Authorization:'Bearer '+fresh})}));
  }
  return res;
}

window.__bootstrap=function(){
  sdkReady=true;
  tryInitPlayer();
};

function tryInitPlayer(){
  if(!sdkReady||!appIsShown||player)return;
  if(typeof Spotify==='undefined'){console.error('[sc] Spotify SDK not loaded');return;}
  player=new Spotify.Player({name:'Spotify Clone',getOAuthToken:async cb=>cb(await getValidToken()),volume:(+volumeEl.value)/100});
  player.addListener('ready',async({device_id})=>{
    deviceId=device_id;
    try{await apiFetch('https://api.spotify.com/v1/me/player',{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify({device_ids:[device_id],play:false})});}catch(e){}
  });
  player.addListener('not_ready',()=>{deviceId=null;});
  player.addListener('initialization_error',({message})=>showToast('Init error: '+message));
  player.addListener('authentication_error',({message})=>showToast('Auth error: '+message));
  player.addListener('account_error',()=>showToast('Spotify Premium is required for playback.',8000));
  player.addListener('playback_error',({message})=>showToast('Playback error: '+message));
  player.addListener('player_state_changed',state=>{
    if(!state)return;
    const t=state.track_window.current_track;
    currentPosition=state.position;
    currentDuration=state.duration;
    isPaused=state.paused;
    activeTrackUri=t.uri;
    updateNowPlaying(t);
    updateActiveTrack(t.uri);
    updateProgressUI();
    startPolling();
    applyEffectsToAudio();
    handleAdMute(t);
  });
  player.connect();
}

function handleAdMute(t){
  if(!settings.adMute){if(adMuted){player.setVolume((+volumeEl.value)/100);adMuted=false;}return;}
  const isAd=t&&t.type==='ad'||(t&&/^advertisement$/i.test((t.name||'').trim()));
  if(isAd&&!adMuted){player.setVolume(0);adMuted=true;}
  else if(!isAd&&adMuted){player.setVolume((+volumeEl.value)/100);adMuted=false;}
}

function startPolling(){
  if(pollTimer)return;
  pollTimer=setInterval(async()=>{
    if(!player)return;
    const state=await player.getCurrentState();
    if(!state)return;
    currentPosition=state.position;
    currentDuration=state.duration;
    isPaused=state.paused;
    playBtn.innerHTML=isPaused?ICON_PLAY:ICON_PAUSE;
    updateProgressUI();
    if(settings.autoSkipShort&&state.track_window&&state.track_window.current_track){
      const cur=state.track_window.current_track;
      if(state.duration>0&&state.duration<60000&&lastAutoSkipUri!==cur.uri){lastAutoSkipUri=cur.uri;player.nextTrack();}
    }
  },500);
}

function updateNowPlaying(t){
  nowTitleEl.textContent=t.name;
  nowArtistEl.textContent=trackArtistText(t);
  const art=trackImage(t);
  currentArtUrl=art;
  setImg(nowCoverEl,art,ICON_NOTE_SMALL);
  playBtn.innerHTML=isPaused?ICON_PLAY:ICON_PAUSE;
  if(settings.bgSource==='album')applyBackground();
}

function updateProgressUI(){
  if(seekDragging)return;
  const pct=currentDuration?(currentPosition/currentDuration):0;
  seekEl.value=Math.round(pct*1000);
  paintRange(seekEl);
  timeCurrentEl.textContent=formatTime(currentPosition);
  timeTotalEl.textContent=formatTime(currentDuration);
}

function updateActiveTrack(uri){document.querySelectorAll('.track-row').forEach(r=>{r.classList.toggle('active',r.dataset.uri===uri);});}

function findSdkAudio(){
  const audios=document.querySelectorAll('audio');
  for(const el of audios){if(el.src&&el.src.startsWith('blob:'))return el;}
  for(const el of audios){if(el.srcObject)return el;}
  return null;
}

function applyPitchToElement(el,rate){
  try{
    el.playbackRate=rate;
    if('preservesPitch' in el)el.preservesPitch=false;
    if('mozPreservesPitch' in el)el.mozPreservesPitch=false;
    if('webkitPreservesPitch' in el)el.webkitPreservesPitch=false;
    return true;
  }catch(e){return false;}
}

function applyEffectsToAudio(){
  const el=findSdkAudio();
  if(el){sdkAudioEl=el;applyPitchToElement(el,currentPitch);}
}

async function tryHookBass(){
  if(bassHookState==='success')return true;
  if(bassHookState==='failed')return false;
  if(bassHookState==='trying')return false;
  bassHookState='trying';updateFxStatus();
  sdkAudioEl=findSdkAudio();
  if(!sdkAudioEl){bassHookState='failed';updateFxStatus();return false;}
  applyPitchToElement(sdkAudioEl,currentPitch);
  try{
    const Ctx=window.AudioContext||window.webkitAudioContext;
    const ctx=new Ctx();
    const src=ctx.createMediaElementSource(sdkAudioEl);
    const filter=ctx.createBiquadFilter();
    filter.type='lowshelf';filter.frequency.value=200;filter.gain.value=currentBass;
    src.connect(filter);filter.connect(ctx.destination);
    const analyser=ctx.createAnalyser();analyser.fftSize=256;filter.connect(analyser);
    await new Promise(r=>setTimeout(r,1200));
    const data=new Uint8Array(analyser.frequencyBinCount);
    analyser.getByteFrequencyData(data);
    let max=0;for(let i=0;i<data.length;i++)if(data[i]>max)max=data[i];
    if(max===0&&!isPaused){bassHookState='failed';updateFxStatus();return false;}
    bassCtx=ctx;bassFilter=filter;bassHookState='success';updateFxStatus();return true;
  }catch(e){bassHookState='failed';updateFxStatus();return false;}
}

function updateFxStatus(){
  if(bassHookState==='success'){fxStatus.textContent='Active';fxStatus.className='fx-status active';}
  else if(bassHookState==='failed'){fxStatus.textContent='Bass unavailable';fxStatus.className='fx-status error';}
  else if(bassHookState==='trying'){fxStatus.textContent='Hooking…';fxStatus.className='fx-status warn';}
  else if(currentPitch!==1){fxStatus.textContent='Pitch active';fxStatus.className='fx-status active';}
  else{fxStatus.textContent='Idle';fxStatus.className='fx-status';}
}

function setPitch(rate){
  currentPitch=rate;pitchSlider.value=Math.round(rate*100);paintRange(pitchSlider);
  pitchValueEl.textContent=rate.toFixed(2)+'×';
  if(sdkAudioEl)applyPitchToElement(sdkAudioEl,rate);else applyEffectsToAudio();
  updateFxStatus();
}
function setBass(db){
  currentBass=db;bassSlider.value=db;paintRange(bassSlider);
  bassValueEl.textContent=(db>=0?'+':'')+db+' dB';
  if(bassFilter)bassFilter.gain.value=db;
  else tryHookBass().then(ok=>{if(ok&&bassFilter)bassFilter.gain.value=db;});
  updateFxStatus();
}

async function fetchUserProfile(){
  const res=await apiFetch('https://api.spotify.com/v1/me');
  if(!res.ok)return null;
  return await res.json();
}

async function fetchPlaylists(){
  const all=[];let url='https://api.spotify.com/v1/me/playlists?limit=50';
  while(url){
    const res=await apiFetch(url);
    if(!res.ok)throw new Error('Could not load playlists ('+res.status+')');
    const data=await res.json();
    (data.items||[]).forEach(p=>{if(p&&p.id)all.push(p);});
    url=data.next;
  }
  return all;
}

async function fetchPlaylist(id){
  return cachedFetch('pl:'+id,async()=>{
    const res=await apiFetch('https://api.spotify.com/v1/playlists/'+id);
    if(!res.ok)throw new Error('Could not load playlist ('+res.status+')');
    return await res.json();
  });
}

async function fetchPlaylistTracks(id){
  return cachedFetch('pl-tracks:'+id,async()=>{
    const tracks=[];let url='https://api.spotify.com/v1/playlists/'+id+'/items?limit=100';
    while(url){
      const res=await apiFetch(url);
      if(!res.ok)throw new Error('Could not load playlist tracks ('+res.status+')');
      const data=await res.json();
      const items=(data.items&&Array.isArray(data.items))?data.items:((data.tracks&&data.tracks.items)||[]);
      items.forEach(row=>{
        if(!row)return;
        const c=row.item||row.track;
        if(!c||typeof c!=='object')return;
        if(!c.id)return;
        if(c.is_local)return;
        if(c.type&&c.type!=='track'&&c.type!=='episode')return;
        tracks.push(c);
      });
      url=data.next||(data.tracks&&data.tracks.next)||null;
    }
    return tracks;
  });
}

async function searchTracks(query,offset){
  offset=offset||0;
  const key='search:'+query+':'+offset;
  const cached=searchCache.get(key);
  if(cached&&Date.now()-cached.ts<SEARCH_TTL)return cached.data;
  const url='https://api.spotify.com/v1/search?'+new URLSearchParams({q:query,type:'track',limit:10,offset:offset});
  const res=await apiFetch(url);
  if(!res.ok){const err=await res.json().catch(()=>({}));throw new Error((err.error&&err.error.message)||('Search failed ('+res.status+')'));}
  const data=await res.json();
  const items=(data.tracks&&data.tracks.items)||[];
  const result={tracks:items.filter(t=>t&&t.id&&!t.is_local),total:(data.tracks&&data.tracks.total)||0,next:(data.tracks&&data.tracks.next)||null};
  searchCache.set(key,{data:result,ts:Date.now()});
  return result;
}

function interpretMutationError(status,body){
  const raw=(body&&body.error&&body.error.message)||('HTTP '+status);
  const lower=raw.toLowerCase();
  if(status===403){
    if(lower.includes('scope'))return {message:'Missing permission to edit playlists. Sign out and sign in again, then approve all permissions.',kind:'scope'};
    if(lower.includes('premium'))return {message:'Spotify Premium is required to modify playlists.',kind:'premium'};
    if(lower.includes('collaborat'))return {message:'You can only add to playlists you own or collaborate on.',kind:'owner'};
    return {message:'Spotify refused this change (403). You may not own this playlist, or your session lacks edit permission.',kind:'forbidden'};
  }
  if(status===404)return {message:'Playlist or track not found.',kind:'notfound'};
  if(status===429)return {message:'Rate limited by Spotify. Wait a few seconds and try again.',kind:'ratelimit'};
  return {message:raw,kind:'error'};
}

async function addTrackToPlaylist(playlistId,trackUri){
  const body=JSON.stringify({uris:[trackUri]});
  const opts={method:'POST',headers:{'Content-Type':'application/json'},body:body};
  let res=await apiFetch('https://api.spotify.com/v1/playlists/'+playlistId+'/items',opts);
  if(res.status===404)res=await apiFetch('https://api.spotify.com/v1/playlists/'+playlistId+'/tracks',opts);
  if(res.ok){invalidatePlaylist(playlistId);return {ok:true};}
  const errBody=await res.json().catch(()=>({}));
  const info=interpretMutationError(res.status,errBody);
  return {ok:false,status:res.status,message:info.message,kind:info.kind};
}

async function removeTrackFromPlaylist(playlistId,trackUri){
  const body=JSON.stringify({tracks:[{uri:trackUri}]});
  const opts={method:'DELETE',headers:{'Content-Type':'application/json'},body:body};
  let res=await apiFetch('https://api.spotify.com/v1/playlists/'+playlistId+'/items',opts);
  if(res.status===404||res.status===405)res=await apiFetch('https://api.spotify.com/v1/playlists/'+playlistId+'/tracks',opts);
  if(res.ok){invalidatePlaylist(playlistId);return {ok:true};}
  const errBody=await res.json().catch(()=>({}));
  const info=interpretMutationError(res.status,errBody);
  return {ok:false,status:res.status,message:info.message,kind:info.kind};
}

async function createPlaylist(name){
  const meRes=await apiFetch('https://api.spotify.com/v1/me');
  if(!meRes.ok)throw new Error('Could not get profile');
  const me=await meRes.json();
  const res=await apiFetch('https://api.spotify.com/v1/users/'+me.id+'/playlists',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name,public:false,description:'Created with Spotify Clone'})});
  if(!res.ok)throw new Error('Could not create playlist');
  return await res.json();
}

async function ensureMembership(ids,onUpdate){
  const pending=ids.filter(id=>!plMembership.has(id)&&!membershipLoading.has(id));
  for(const id of pending){
    membershipLoading.add(id);
    try{const tracks=await fetchPlaylistTracks(id);plMembership.set(id,new Set(tracks.map(t=>t.uri)));}
    catch(e){plMembership.set(id,new Set());}
    membershipLoading.delete(id);
    if(onUpdate)onUpdate(id);
  }
}

function setActiveNav(name){document.querySelectorAll('.nav-item').forEach(n=>{n.classList.toggle('active',n.dataset.nav===name);});}

function renderUserFooter(){
  if(!currentUserProfile){sidebarAvatar.textContent='?';sidebarUsername.textContent='Signed in';return;}
  const img=pickImage(currentUserProfile.images);
  if(img){
    sidebarAvatar.innerHTML='';
    const el=document.createElement('img');el.alt='';el.setAttribute('referrerpolicy','no-referrer');el.src=img;
    el.addEventListener('error',()=>{sidebarAvatar.textContent=(currentUserProfile.display_name||'?').charAt(0).toUpperCase();},{once:true});
    sidebarAvatar.appendChild(el);
  }else{sidebarAvatar.textContent=(currentUserProfile.display_name||'?').charAt(0).toUpperCase();}
  sidebarUsername.textContent=currentUserProfile.display_name||currentUserProfile.id||'Signed in';
}

function renderSidebar(){
  playlistListEl.innerHTML='';
  userPlaylists.forEach(p=>{
    const item=document.createElement('div');
    item.className='playlist-item'+(p.id===activePlaylistId?' active':'');
    item.dataset.id=p.id;item.title=p.name;
    const thumb=document.createElement('div');thumb.className='playlist-item-thumb';
    setImg(thumb,pickImage(p.images),ICON_NOTE_SMALL,true);
    const info=document.createElement('div');info.className='playlist-item-info';
    const name=document.createElement('div');name.className='playlist-name';name.textContent=p.name;
    const meta=document.createElement('div');meta.className='playlist-meta';meta.textContent='Playlist • '+playlistTrackCount(p)+' tracks';
    info.appendChild(name);info.appendChild(meta);
    item.appendChild(thumb);item.appendChild(info);
    item.addEventListener('click',()=>{openPlaylist(p.id);closeSidebar();});
    playlistListEl.appendChild(item);
  });
}

function renderHome(){
  activePlaylistId=null;setActiveNav('home');renderSidebar();
  mainEl.innerHTML='';
  const wrap=document.createElement('div');wrap.className='home';
  const h=document.createElement('h1');h.textContent='Your playlists';wrap.appendChild(h);
  if(!userPlaylists.length){
    const empty=document.createElement('div');empty.className='empty-msg';empty.textContent='No playlists found in your library.';
    wrap.appendChild(empty);
  }else{
    const grid=document.createElement('div');grid.className='playlist-grid';
    userPlaylists.forEach(p=>{
      const card=document.createElement('div');card.className='playlist-card';
      const cover=document.createElement('div');cover.className='cover-wrap';
      setImg(cover,pickImage(p.images),ICON_NOTE_BIG,true);
      const fab=document.createElement('button');fab.className='play-fab';fab.innerHTML=ICON_PLAY;
      fab.addEventListener('click',e=>{e.stopPropagation();openPlaylist(p.id,true);});
      cover.appendChild(fab);
      const nameEl=document.createElement('div');nameEl.className='card-name';nameEl.textContent=p.name;
      const desc=document.createElement('div');desc.className='card-desc';desc.textContent='Playlist • '+playlistTrackCount(p)+' tracks';
      card.appendChild(cover);card.appendChild(nameEl);card.appendChild(desc);
      card.addEventListener('click',()=>openPlaylist(p.id));
      grid.appendChild(card);
    });
    wrap.appendChild(grid);
  }
  mainEl.appendChild(wrap);mainEl.scrollTop=0;
}

async function openPlaylist(id,autoPlay){
  activePlaylistId=id;setActiveNav(null);renderSidebar();
  mainEl.innerHTML='<div class="loading-msg">Loading playlist…</div>';
  try{
    const [pl,tracks]=await Promise.all([fetchPlaylist(id),fetchPlaylistTracks(id)]);
    plMembership.set(id,new Set(tracks.map(t=>t.uri)));
    const idx=userPlaylists.findIndex(p=>p.id===id);
    if(idx>=0){
      userPlaylists[idx]._actualCount=tracks.length;
      const metaEl=document.querySelector('.playlist-item[data-id="'+id+'"] .playlist-meta');
      if(metaEl)metaEl.textContent='Playlist • '+tracks.length+' tracks';
    }
    renderPlaylistView(pl,tracks);
    if(autoPlay&&tracks.length)playTrackInPlaylist(tracks[0].uri,id);
  }catch(e){
    mainEl.innerHTML='<div class="empty-msg">Failed to load playlist. '+(e.message||'')+'</div>';
    showToast(e.message||'Could not load playlist');
  }
}

function renderPlaylistView(pl,tracks){
  mainEl.innerHTML='';
  const wrap=document.createElement('div');wrap.className='playlist-view';
  const header=document.createElement('div');header.className='playlist-header';
  const coverBox=document.createElement('div');coverBox.className='ph-big';
  setImg(coverBox,pickImage(pl.images),ICON_NOTE_BIG);
  const info=document.createElement('div');info.className='playlist-header-info';
  const type=document.createElement('div');type.className='playlist-type';type.textContent='Playlist';
  const title=document.createElement('div');title.className='playlist-title';title.textContent=pl.name;
  const desc=document.createElement('div');desc.className='playlist-desc';
  const owner=(pl.owner&&pl.owner.display_name)?pl.owner.display_name:'Spotify';
  desc.innerHTML='<strong>'+owner+'</strong> • '+tracks.length+' tracks';
  info.appendChild(type);info.appendChild(title);info.appendChild(desc);
  header.appendChild(coverBox);header.appendChild(info);
  const actions=document.createElement('div');actions.className='playlist-actions';
  const bigPlay=document.createElement('button');bigPlay.className='big-play';bigPlay.innerHTML=ICON_PLAY;
  bigPlay.addEventListener('click',()=>{if(tracks.length)playTrackInPlaylist(tracks[0].uri,pl.id);});
  actions.appendChild(bigPlay);
  const head=document.createElement('div');head.className='tracklist-head';
  head.innerHTML='<span style="text-align:right">#</span><span></span><span>Title</span><span>Album</span><span style="text-align:right">⏱</span><span></span>';
  const list=document.createElement('div');list.className='tracklist';
  tracks.forEach((t,i)=>list.appendChild(buildTrackRow(t,i,()=>playTrackInPlaylist(t.uri,pl.id))));
  if(!tracks.length){
    const empty=document.createElement('div');empty.className='empty-msg';empty.textContent='No playable tracks in this playlist.';
    list.appendChild(empty);
  }
  wrap.appendChild(header);wrap.appendChild(actions);wrap.appendChild(head);wrap.appendChild(list);
  mainEl.appendChild(wrap);mainEl.scrollTop=0;
}

function buildTrackRow(t,index,onClick){
  const row=document.createElement('div');
  row.className='track-row';row.dataset.uri=t.uri;
  const num=document.createElement('div');num.className='num';
  const numText=document.createElement('span');numText.className='num-text';numText.textContent=index+1;
  const playIcon=document.createElement('span');playIcon.className='play-icon';playIcon.innerHTML=ICON_PLAY;
  num.appendChild(numText);num.appendChild(playIcon);
  const art=document.createElement('div');art.className='art';
  setImg(art,trackImage(t),ICON_NOTE_SMALL,true);
  const titleCell=document.createElement('div');titleCell.className='title-cell';
  const tName=document.createElement('div');tName.className='track-name';tName.textContent=t.name;
  const tArtist=document.createElement('div');tArtist.className='track-artist';tArtist.textContent=trackArtistText(t);
  titleCell.appendChild(tName);titleCell.appendChild(tArtist);
  const albumCell=document.createElement('div');albumCell.className='track-album';
  albumCell.textContent=(t.album&&t.album.name)||(t.show&&t.show.name)||'';
  const dur=document.createElement('div');dur.className='track-duration';dur.textContent=formatTime(t.duration_ms);
  const addBtn=document.createElement('button');addBtn.className='track-add-btn';addBtn.title='Add to playlist';addBtn.innerHTML=ICON_PLUS;
  addBtn.addEventListener('click',e=>{e.stopPropagation();openAddPopover(t,addBtn);});
  row.appendChild(num);row.appendChild(art);row.appendChild(titleCell);row.appendChild(albumCell);row.appendChild(dur);row.appendChild(addBtn);
  row.addEventListener('click',onClick);
  return row;
}

function openAddPopover(track,anchorEl){
  document.querySelectorAll('.add-popover').forEach(el=>el.remove());
  const pop=document.createElement('div');pop.className='add-popover';
  const isMobile=document.body.dataset.device==='mobile';
  if(!isMobile){
    const rect=anchorEl.getBoundingClientRect();
    let top=rect.bottom+8,left=Math.min(rect.left-260,window.innerWidth-356);
    left=Math.max(12,left);
    if(top+500>window.innerHeight)top=Math.max(12,rect.top-500-8);
    pop.style.top=top+'px';pop.style.left=left+'px';
  }
  const header=document.createElement('div');header.className='add-popover-header';header.textContent=track.name;
  pop.appendChild(header);
  const status=document.createElement('div');status.className='add-popover-status';status.textContent='Checking your playlists…';
  pop.appendChild(status);
  const warning=document.createElement('div');warning.className='add-popover-warning';
  pop.appendChild(warning);
  const filter=document.createElement('input');filter.className='add-filter';filter.type='text';filter.placeholder='Filter playlists';
  pop.appendChild(filter);
  const list=document.createElement('div');list.className='add-popover-list';pop.appendChild(list);
  const editable=userPlaylists.filter(canModifyPlaylist);
  const rows=new Map();
  const ids=editable.slice(0,80).map(p=>p.id);
  if(!editable.length){
    const empty=document.createElement('div');empty.className='add-popover-empty';
    empty.textContent=userPlaylists.length?'None of your playlists are editable by this account.':'No playlists loaded.';
    list.appendChild(empty);status.textContent='No editable playlists';
  }
  editable.forEach(p=>{
    const row=document.createElement('button');row.className='add-row';
    row.innerHTML='<div class="add-thumb"></div><div class="add-info"><div class="add-name"></div><div class="add-meta"></div></div><div class="add-state"></div>';
    setImg(row.querySelector('.add-thumb'),pickImage(p.images),ICON_NOTE_SMALL,true);
    row.querySelector('.add-name').textContent=p.name;
    const metaEl=row.querySelector('.add-meta'),stateEl=row.querySelector('.add-state');
    metaEl.textContent=playlistTrackCount(p)+' tracks';
    stateEl.innerHTML='<span class="mini-spinner"></span>';
    const entry={row,metaEl,stateEl,busy:false};
    rows.set(p.id,entry);
    row.addEventListener('click',async()=>{
      if(entry.busy)return;
      const set=plMembership.get(p.id);
      if(!set){showToast('Still checking this playlist',1800);return;}
      entry.busy=true;stateEl.innerHTML='<span class="mini-spinner"></span>';warning.classList.remove('show');
      const has=set.has(track.uri);
      try{
        const res=has?await removeTrackFromPlaylist(p.id,track.uri):await addTrackToPlaylist(p.id,track.uri);
        if(res.ok){
          if(has){set.delete(track.uri);invalidatePlaylist(p.id);showToast('Removed from "'+p.name+'"',2000,'success');}
          else{set.add(track.uri);invalidatePlaylist(p.id);showToast('Added to "'+p.name+'"',2000,'success');}
          paintRow(p.id);refreshMembershipSummary();
          const idx=userPlaylists.findIndex(x=>x.id===p.id);
          if(idx>=0){
            userPlaylists[idx]._actualCount=set.size;
            const side=document.querySelector('.playlist-item[data-id="'+p.id+'"] .playlist-meta');
            if(side)side.textContent='Playlist • '+set.size+' tracks';
          }
        }else{
          paintRow(p.id);warning.innerHTML='';
          const msg=document.createElement('div');msg.textContent=res.message;warning.appendChild(msg);
          if(res.kind==='scope'||res.kind==='forbidden'){
            const btn=document.createElement('button');btn.textContent='Sign out & reauthorize';
            btn.addEventListener('click',()=>{pop.remove();signOut();});
            warning.appendChild(btn);
          }
          warning.classList.add('show');
        }
      }catch(err){paintRow(p.id);showToast('Failed: '+(err.message||'unknown error'),4500);}
      finally{entry.busy=false;}
    });
    list.appendChild(row);
  });
  function paintRow(id){
    const entry=rows.get(id);if(!entry)return;
    const set=plMembership.get(id);
    if(!set){entry.stateEl.innerHTML='<span class="mini-spinner"></span>';entry.row.classList.remove('in');return;}
    const has=set.has(track.uri);
    entry.row.classList.toggle('in',has);
    entry.stateEl.innerHTML=has?ICON_CHECK:ICON_PLUS;
    entry.stateEl.title=has?'Click to remove from this playlist':'Click to add to this playlist';
    entry.metaEl.textContent=set.size+' tracks'+(has?' • In playlist':'');
    entry.row.classList.remove('just-changed');void entry.row.offsetWidth;entry.row.classList.add('just-changed');
    setTimeout(()=>entry.row.classList.remove('just-changed'),450);
  }
  function refreshMembershipSummary(){
    let known=0,inside=0;
    rows.forEach((e,id)=>{const s=plMembership.get(id);if(!s)return;known++;if(s.has(track.uri))inside++;});
    if(known<rows.size)status.textContent='Checking your playlists… '+known+'/'+rows.size;
    else if(known===0)status.textContent='No editable playlists';
    else status.textContent='In '+inside+' of '+known+' editable playlists • click a check mark to remove';
  }
  filter.addEventListener('input',()=>{
    const q=filter.value.trim().toLowerCase();
    rows.forEach((entry,id)=>{
      const p=userPlaylists.find(x=>x.id===id);
      entry.row.style.display=!q||(p&&p.name.toLowerCase().includes(q))?'':'none';
    });
  });
  const newBtn=document.createElement('button');newBtn.className='add-popover-new';newBtn.innerHTML=ICON_PLUS+'<span>New playlist…</span>';
  newBtn.addEventListener('click',async()=>{
    const name=prompt('Name for the new playlist:');
    if(!name||!name.trim())return;
    try{
      const pl=await createPlaylist(name.trim());
      const res=await addTrackToPlaylist(pl.id,track.uri);
      userPlaylists.unshift(pl);
      plMembership.set(pl.id,new Set(res.ok?[track.uri]:[]));
      renderSidebar();pop.remove();
      if(res.ok)showToast('Created "'+name.trim()+'" and added track',2400,'success');
      else showToast('Playlist created, track not added: '+res.message,4500);
    }catch(e){showToast('Could not create playlist: '+e.message,4500);}
  });
  pop.appendChild(newBtn);
  document.body.appendChild(pop);
  refreshMembershipSummary();
  ensureMembership(ids,(id)=>{if(id)paintRow(id);refreshMembershipSummary();});
  setTimeout(()=>{
    const close=e=>{if(!pop.contains(e.target)&&e.target!==anchorEl){pop.remove();document.removeEventListener('mousedown',close);document.removeEventListener('touchstart',close);}};
    document.addEventListener('mousedown',close);document.addEventListener('touchstart',close);
  },0);
}

function renderSearchView(){
  activePlaylistId=null;setActiveNav('search');renderSidebar();
  mainEl.innerHTML='';
  const wrap=document.createElement('div');wrap.className='search-view';
  const h=document.createElement('h1');h.textContent='Search';wrap.appendChild(h);
  const input=document.createElement('input');input.type='text';input.className='search-input';input.placeholder='What do you want to listen to?';input.value=searchState.query||'';
  input.addEventListener('keydown',e=>{if(e.key==='Enter'){clearTimeout(searchDebounce);const q=input.value.trim();if(q)doSearch(q);}});
  input.addEventListener('input',()=>{
    clearTimeout(searchDebounce);
    const q=input.value.trim();
    if(!q){searchState={query:'',tracks:[],hasMore:false,offset:0,total:0};renderSearchResults();return;}
    searchDebounce=setTimeout(()=>doSearch(q),400);
  });
  wrap.appendChild(input);
  const results=document.createElement('div');results.id='search-results';results.className='search-results';
  wrap.appendChild(results);
  mainEl.appendChild(wrap);
  if(!input.value)input.focus();
  renderSearchResults();
}

function renderSearchResults(){
  const results=document.getElementById('search-results');if(!results)return;
  results.innerHTML='';
  if(!searchState.query){
    const empty=document.createElement('div');empty.className='empty-msg';empty.textContent='Type a song, artist, or album to start searching.';
    results.appendChild(empty);return;
  }
  if(!searchState.tracks.length){
    const empty=document.createElement('div');empty.className='empty-msg';empty.textContent='No results for "'+searchState.query+'".';
    results.appendChild(empty);return;
  }
  const toolbar=document.createElement('div');toolbar.className='search-toolbar';
  const info=document.createElement('div');info.className='playlist-desc';info.style.margin='0';
  info.textContent='Showing '+searchState.tracks.length+' of '+searchState.total+' results';
  const playAll=document.createElement('button');playAll.className='ghost-pill';playAll.textContent='Play all results';
  playAll.addEventListener('click',()=>playSearchResult(0));
  toolbar.appendChild(info);toolbar.appendChild(playAll);results.appendChild(toolbar);
  const head=document.createElement('div');head.className='search-results-head';
  head.innerHTML='<span style="text-align:right">#</span><span></span><span>Title</span><span>Album</span><span style="text-align:right">⏱</span><span></span>';
  results.appendChild(head);
  const list=document.createElement('div');
  searchState.tracks.forEach((t,i)=>list.appendChild(buildTrackRow(t,i,()=>playSearchResult(i))));
  results.appendChild(list);
  if(searchState.hasMore){
    const more=document.createElement('button');more.className='load-more-btn';more.textContent='Load more';
    more.addEventListener('click',async()=>{
      more.disabled=true;more.textContent='Loading…';
      try{
        const next=await searchTracks(searchState.query,searchState.offset);
        searchState.tracks.push(...next.tracks);
        searchState.offset+=next.tracks.length;
        searchState.hasMore=!!next.next;
        renderSearchResults();
      }catch(e){showToast('Could not load more: '+e.message);more.disabled=false;more.textContent='Load more';}
    });
    results.appendChild(more);
  }
}

async function doSearch(query){
  searchState={query,tracks:[],hasMore:false,offset:0,total:0};
  const results=document.getElementById('search-results');if(!results)return;
  results.innerHTML='<div class="loading-msg">Searching…</div>';
  try{
    const res=await searchTracks(query,0);
    if(searchState.query!==query)return;
    searchState.tracks=res.tracks;searchState.offset=res.tracks.length;
    searchState.hasMore=!!res.next;searchState.total=res.total;
    renderSearchResults();
  }catch(e){results.innerHTML='<div class="empty-msg">Search failed: '+e.message+'</div>';}
}

async function playSearchResult(index){
  if(!deviceId){showToast('Player is starting up. Try again in a moment.');return;}
  const uris=searchState.tracks.map(t=>t.uri).filter(Boolean);if(!uris.length)return;
  try{
    const res=await apiFetch('https://api.spotify.com/v1/me/player/play?device_id='+deviceId,{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify({uris,offset:{position:index}})});
    if(!res.ok){const e=await res.json().catch(()=>({}));showToast('Playback failed: '+((e.error&&e.error.message)||res.status));}
  }catch(e){showToast('Playback failed: '+e.message);}
}

async function playTrackInPlaylist(trackUri,playlistId){
  if(!deviceId){showToast('Player is starting up. Try again in a moment.');return;}
  try{
    let res=await apiFetch('https://api.spotify.com/v1/me/player/play?device_id='+deviceId,{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify({context_uri:'spotify:playlist:'+playlistId,offset:{uri:trackUri}})});
    if(!res.ok)res=await apiFetch('https://api.spotify.com/v1/me/player/play?device_id='+deviceId,{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify({uris:[trackUri]})});
    if(!res.ok){const e=await res.json().catch(()=>({}));showToast('Playback failed: '+((e.error&&e.error.message)||res.status));}
  }catch(e){showToast('Playback failed: '+e.message);}
}

async function playSingleUri(uri){
  if(!deviceId){showToast('Player is starting up. Try again in a moment.');return;}
  try{
    const res=await apiFetch('https://api.spotify.com/v1/me/player/play?device_id='+deviceId,{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify({uris:[uri]})});
    if(!res.ok){const e=await res.json().catch(()=>({}));showToast('Playback failed: '+((e.error&&e.error.message)||res.status));}
  }catch(e){showToast('Playback failed: '+e.message);}
}

async function openQueue(){
  queueDrawer.classList.add('open');
  queueBody.innerHTML='<div class="loading-msg">Loading queue…</div>';
  try{
    const res=await apiFetch('https://api.spotify.com/v1/me/player/queue');
    if(!res.ok)throw new Error('Queue unavailable ('+res.status+')');
    const data=await res.json();queueBody.innerHTML='';
    if(data.currently_playing){
      const label=document.createElement('div');label.className='queue-label';label.textContent='Now playing';
      queueBody.appendChild(label);queueBody.appendChild(queueItem(data.currently_playing,true));
    }
    const upcoming=(data.queue||[]).slice(0,40);
    const label2=document.createElement('div');label2.className='queue-label';label2.textContent='Next up';
    queueBody.appendChild(label2);
    if(!upcoming.length){
      const empty=document.createElement('div');empty.className='empty-msg';empty.textContent='Nothing queued.';
      queueBody.appendChild(empty);
    }
    upcoming.forEach(t=>queueBody.appendChild(queueItem(t,false)));
  }catch(e){queueBody.innerHTML='<div class="empty-msg">'+e.message+'</div>';}
}

function queueItem(t,isCurrent){
  const btn=document.createElement('button');btn.className='queue-item';
  const thumb=document.createElement('div');thumb.className='queue-thumb';
  setImg(thumb,trackImage(t),ICON_NOTE_SMALL,true);
  const info=document.createElement('div');info.className='queue-info';
  const n=document.createElement('div');n.className='queue-name';n.textContent=t.name;
  const a=document.createElement('div');a.className='queue-artist';a.textContent=trackArtistText(t);
  info.appendChild(n);info.appendChild(a);
  btn.appendChild(thumb);btn.appendChild(info);
  if(isCurrent)btn.style.background='rgba(255,255,255,0.06)';
  if(t.uri)btn.addEventListener('click',()=>playSingleUri(t.uri));
  return btn;
}

function drawSettings(){
  mainEl.innerHTML=`
  <div class="settings">
    <div class="settings-head">
      <div><h1>Settings</h1><div class="settings-sub">Themes, backgrounds and playback</div></div>
      <button class="ghost-pill" id="reset-settings">Reset all</button>
    </div>
    <div class="tabs">
      ${['themes','appearance','background','playback'].map(t=>`<button class="tab-btn ${settingsTab===t?'active':''}" data-tab="${t}">${tabLabel(t)}</button>`).join('')}
    </div>
    <div id="tab-body">${tabBody(settingsTab)}</div>
    <div class="settings-foot">All themes load from <code>Themes/</code> next to this page. Nothing is hardcoded.</div>
  </div>`;
  bindSettings();
  mainEl.scrollTop=0;
}

function tabLabel(t){return {themes:'Themes',appearance:'Appearance',background:'Background',playback:'Playback'}[t]||t;}

function escapeHtml(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}

function emptyThemesBlock(){
  return `
    <div class="themes-status warn">
      <div><strong>No themes loaded — using default styles</strong><small>${themesStatus.message||'Add a Themes folder next to this file.'}</small></div>
      <button class="btn-ghost" id="reload-themes">Reload</button>
    </div>
    <div class="setting-group">
      <div class="themes-empty">
        <p><strong>Add themes to <code>Themes/</code>:</strong></p>
        <ol>
          <li>Create <code>Themes/manifest.json</code> listing your themes.</li>
          <li>Add <code>Themes/&lt;Name&gt;/color.ini</code> per theme with a <code>[Base]</code> section (main, sidebar, text, subtext, button).</li>
          <li>Optionally add <code>Themes/&lt;Name&gt;/user.css</code> for extra styling.</li>
          <li>Click <strong>Reload</strong> above.</li>
        </ol>
        <p style="margin-top:16px"><strong>Example <code>manifest.json</code>:</strong></p>
        <pre style="text-align:left;background:rgba(255,255,255,0.05);padding:12px;border-radius:8px;font-size:11.5px;overflow-x:auto;margin-top:8px">${escapeHtml(JSON.stringify({themes:[{id:'Blossom',name:'Blossom'},{id:'Dracula',name:'Dracula'}]},null,2))}</pre>
      </div>
    </div>`;
}

function tabBody(tab){
  if(tab==='themes'){
    if(!THEMES.length)return emptyThemesBlock();
    const t=currentTheme();
    const statusClass=themesStatus.state==='ok'?'ok':themesStatus.state==='error'?'err':'warn';
    const accentInitial=settings.accent||(t&&t.brand)||'#1DB954';
    return `
    <div class="themes-status ${statusClass}">
      <div><strong>${THEMES.length} theme${THEMES.length===1?'':'s'} loaded</strong><small>${themesStatus.message||''}</small></div>
      <button class="btn-ghost" id="reload-themes">Reload folder</button>
    </div>
    <div class="theme-grid">
      ${THEMES.map(x=>`
        <button class="theme-card ${settings.theme===x.id?'active':''}" data-theme="${x.id}">
          <div class="swatches">
            <span style="background:${x.bg}"></span><span style="background:${x.elevated}"></span>
            <span style="background:${x.card}"></span><span style="background:${x.brand}"></span>
            <span style="background:${x.text}"></span>
          </div>
          <div class="theme-name">${escapeHtml(x.name)}</div>
        </button>`).join('')}
    </div>
    <div class="setting-group" style="margin-top:18px">
      <div class="setting-row">
        <div><div class="setting-label">Apply theme CSS</div><div class="setting-sub">Load each theme's user.css file</div></div>
        <div class="setting-control"><label class="switch"><input type="checkbox" id="apply-raw-css" ${settings.applyRawCss?'checked':''}><span></span></label></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Inject Spicetify variables</div><div class="setting-sub">Expose --spice-* CSS variables</div></div>
        <div class="setting-control"><label class="switch"><input type="checkbox" id="apply-spice-vars" ${settings.applySpiceVars?'checked':''}><span></span></label></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Custom accent</div><div class="setting-sub">Override the theme's accent color</div></div>
        <div class="setting-control">
          <input type="color" id="accent-color" value="${accentInitial}" style="width:40px;height:32px;border:none;border-radius:8px;background:transparent;cursor:pointer;flex-shrink:0">
          <label class="switch"><input type="checkbox" id="use-accent" ${settings.useAccent?'checked':''}><span></span></label>
        </div>
      </div>
    </div>`;
  }
  if(tab==='appearance'){
    return `
    <div class="setting-group">
      <div class="setting-row">
        <div><div class="setting-label">Corner radius</div><div class="setting-sub">Roundness of panels and cards</div></div>
        <div class="setting-control"><input type="range" id="radius-range" min="0" max="24" value="${settings.radius}"><span class="range-val" id="radius-val">${settings.radius}px</span></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Sidebar width</div><div class="setting-sub">Desktop only</div></div>
        <div class="setting-control"><input type="range" id="sidebar-range" min="220" max="380" value="${settings.sidebarWidth}"><span class="range-val" id="sidebar-val">${settings.sidebarWidth}px</span></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Row density</div><div class="setting-sub">Spacing between tracks</div></div>
        <div class="setting-control"><select class="styled-select" id="density-select">
          <option value="compact" ${settings.density==='compact'?'selected':''}>Compact</option>
          <option value="normal" ${settings.density==='normal'?'selected':''}>Normal</option>
          <option value="comfortable" ${settings.density==='comfortable'?'selected':''}>Comfortable</option>
        </select></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Show track numbers</div><div class="setting-sub">Display the index column</div></div>
        <div class="setting-control"><label class="switch"><input type="checkbox" id="show-numbers" ${settings.showNumbers?'checked':''}><span></span></label></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Animations</div><div class="setting-sub">Hover transitions and panel slides</div></div>
        <div class="setting-control"><label class="switch"><input type="checkbox" id="animations" ${settings.animations?'checked':''}><span></span></label></div>
      </div>
    </div>`;
  }
  if(tab==='background'){
    const previewStyle=settings.bgUrl?`background-image:url('${settings.bgSource==='custom'?proxiedUrl(settings.bgUrl):''}')`:'';
    return `
    <div class="setting-group">
      <div class="setting-row">
        <div><div class="setting-label">Background source</div><div class="setting-sub">Theme color, album art, or custom image</div></div>
        <div class="setting-control"><select class="styled-select" id="bg-source">
          <option value="theme" ${settings.bgSource==='theme'?'selected':''}>Theme color</option>
          <option value="album" ${settings.bgSource==='album'?'selected':''}>Album art</option>
          <option value="custom" ${settings.bgSource==='custom'?'selected':''}>Custom image</option>
        </select></div>
      </div>
      <div class="setting-row" style="display:block">
        <div class="setting-label" style="margin-bottom:8px">Image URL</div>
        <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">
          <input class="text-input" id="bg-url" type="text" placeholder="https://example.com/wallpaper.jpg" value="${settings.bgUrl&&!settings.bgUrl.startsWith('data:')?settings.bgUrl:''}">
          <button class="btn-solid" id="bg-apply">Apply</button>
          <button class="btn-ghost" id="bg-upload">Upload</button>
          <button class="btn-ghost" id="bg-clear">Clear</button>
        </div>
        <input type="file" id="bg-file" class="file-input" accept="image/*">
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Blur</div><div class="setting-sub">Soften the background image</div></div>
        <div class="setting-control"><input type="range" id="bg-blur-range" min="0" max="120" value="${settings.bgBlur}"><span class="range-val" id="bg-blur-val">${settings.bgBlur}px</span></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Image opacity</div><div class="setting-sub">How strongly the image shows</div></div>
        <div class="setting-control"><input type="range" id="bg-opacity-range" min="0" max="100" value="${settings.bgOpacity}"><span class="range-val" id="bg-opacity-val">${settings.bgOpacity}%</span></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Darkness</div><div class="setting-sub">Dim the background</div></div>
        <div class="setting-control"><input type="range" id="bg-dim-range" min="0" max="95" value="${settings.bgDim}"><span class="range-val" id="bg-dim-val">${settings.bgDim}%</span></div>
      </div>
      <div class="bg-preview" id="bg-preview" style="${previewStyle}">${settings.bgUrl&&settings.bgSource==='custom'?'':'No custom image set'}</div>
    </div>`;
  }
  return `
    <div class="setting-group">
      <div class="setting-row">
        <div><div class="setting-label">Seek step</div><div class="setting-sub">Seconds skipped with arrow keys</div></div>
        <div class="setting-control"><select class="styled-select" id="seek-step">
          <option value="5" ${settings.seekStep===5?'selected':''}>5 seconds</option>
          <option value="10" ${settings.seekStep===10?'selected':''}>10 seconds</option>
          <option value="15" ${settings.seekStep===15?'selected':''}>15 seconds</option>
          <option value="30" ${settings.seekStep===30?'selected':''}>30 seconds</option>
        </select></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Mute advertisements</div><div class="setting-sub">Instantly mutes ad breaks</div></div>
        <div class="setting-control"><label class="switch"><input type="checkbox" id="ad-mute" ${settings.adMute?'checked':''}><span></span></label></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Auto-skip short tracks</div><div class="setting-sub">Skips clips shorter than one minute</div></div>
        <div class="setting-control"><label class="switch"><input type="checkbox" id="auto-skip" ${settings.autoSkipShort?'checked':''}><span></span></label></div>
      </div>
      <div class="setting-row">
        <div><div class="setting-label">Keyboard shortcuts</div><div class="setting-sub">Space, arrows, N, P, F, Q</div></div>
        <div class="setting-control"><label class="switch"><input type="checkbox" id="shortcuts" ${settings.shortcuts?'checked':''}><span></span></label></div>
      </div>
    </div>`;
}

function bindSettings(){
  document.querySelectorAll('.tab-btn').forEach(btn=>{btn.addEventListener('click',()=>{settingsTab=btn.dataset.tab;drawSettings();});});
  const reset=document.getElementById('reset-settings');
  if(reset)reset.addEventListener('click',()=>{
    if(!confirm('Reset every setting to its default value?'))return;
    settings=Object.assign({},DEFAULT_SETTINGS);
    if(THEMES.length)settings.theme=THEMES[0].id;
    applySettings();drawSettings();showToast('Settings restored',2000,'success');
  });
  const reload=document.getElementById('reload-themes');
  if(reload)reload.addEventListener('click',async()=>{
    reload.disabled=true;reload.textContent='Loading…';
    const n=await refreshThemes();
    drawSettings();
    showToast(n?n+' theme'+(n===1?'':'s')+' loaded':'No themes found',2400,n?'success':'');
  });
  document.querySelectorAll('.theme-card').forEach(card=>{
    card.addEventListener('click',()=>{
      settings.theme=card.dataset.theme;applySettings();
      document.querySelectorAll('.theme-card').forEach(c=>c.classList.toggle('active',c===card));
      const accent=document.getElementById('accent-color');
      const t=currentTheme();if(accent&&t)accent.value=settings.accent||t.brand;
    });
  });
  const applyRawCss=document.getElementById('apply-raw-css');
  if(applyRawCss)applyRawCss.addEventListener('change',()=>{settings.applyRawCss=applyRawCss.checked;applySettings();});
  const applySpice=document.getElementById('apply-spice-vars');
  if(applySpice)applySpice.addEventListener('change',()=>{settings.applySpiceVars=applySpice.checked;applySettings();});
  const useAccent=document.getElementById('use-accent');
  const accentColor=document.getElementById('accent-color');
  if(useAccent)useAccent.addEventListener('change',()=>{
    settings.useAccent=useAccent.checked;
    if(settings.useAccent&&accentColor)settings.accent=accentColor.value;
    applySettings();
  });
  if(accentColor)accentColor.addEventListener('input',()=>{settings.accent=accentColor.value;if(settings.useAccent)applySettings();});
  const radiusRange=document.getElementById('radius-range');
  if(radiusRange)radiusRange.addEventListener('input',()=>{
    settings.radius=+radiusRange.value;document.getElementById('radius-val').textContent=settings.radius+'px';applySettings();
  });
  const sidebarRange=document.getElementById('sidebar-range');
  if(sidebarRange)sidebarRange.addEventListener('input',()=>{
    settings.sidebarWidth=+sidebarRange.value;
    document.getElementById('sidebar-val').textContent=settings.sidebarWidth+'px';
    if(document.body.dataset.device==='desktop')document.documentElement.style.setProperty('--sidebar-w',settings.sidebarWidth+'px');
    saveSettings();
  });
  const densitySelect=document.getElementById('density-select');
  if(densitySelect)densitySelect.addEventListener('change',()=>{settings.density=densitySelect.value;applySettings();});
  const showNumbers=document.getElementById('show-numbers');
  if(showNumbers)showNumbers.addEventListener('change',()=>{settings.showNumbers=showNumbers.checked;applySettings();});
  const animations=document.getElementById('animations');
  if(animations)animations.addEventListener('change',()=>{settings.animations=animations.checked;applySettings();});
  const bgSource=document.getElementById('bg-source');
  if(bgSource)bgSource.addEventListener('change',()=>{settings.bgSource=bgSource.value;applySettings();drawSettings();});
  const bgUrl=document.getElementById('bg-url');
  const bgApply=document.getElementById('bg-apply');
  if(bgApply)bgApply.addEventListener('click',()=>{
    const v=bgUrl.value.trim();settings.bgUrl=v;settings.bgSource=v?'custom':settings.bgSource;
    applySettings();drawSettings();showToast(v?'Background applied':'Background cleared',1800,'success');
  });
  const bgClear=document.getElementById('bg-clear');
  if(bgClear)bgClear.addEventListener('click',()=>{settings.bgUrl='';settings.bgSource='theme';applySettings();drawSettings();});
  const bgUpload=document.getElementById('bg-upload');
  const bgFile=document.getElementById('bg-file');
  if(bgUpload&&bgFile){
    bgUpload.addEventListener('click',()=>bgFile.click());
    bgFile.addEventListener('change',()=>{
      const f=bgFile.files&&bgFile.files[0];if(!f)return;
      if(!f.type.startsWith('image/')){showToast('Please choose an image file',2500);return;}
      if(f.size>1500000){showToast('Image larger than 1.5 MB, pick a smaller one',3500);return;}
      const reader=new FileReader();
      reader.onload=()=>{settings.bgUrl=String(reader.result);settings.bgSource='custom';applySettings();drawSettings();showToast('Background image uploaded',2000,'success');};
      reader.readAsDataURL(f);
    });
  }
  const bgBlur=document.getElementById('bg-blur-range');
  if(bgBlur)bgBlur.addEventListener('input',()=>{settings.bgBlur=+bgBlur.value;document.getElementById('bg-blur-val').textContent=settings.bgBlur+'px';applySettings();});
  const bgOpacity=document.getElementById('bg-opacity-range');
  if(bgOpacity)bgOpacity.addEventListener('input',()=>{settings.bgOpacity=+bgOpacity.value;document.getElementById('bg-opacity-val').textContent=settings.bgOpacity+'%';applySettings();});
  const bgDimRange=document.getElementById('bg-dim-range');
  if(bgDimRange)bgDimRange.addEventListener('input',()=>{settings.bgDim=+bgDimRange.value;document.getElementById('bg-dim-val').textContent=settings.bgDim+'%';applySettings();});
  const seekStep=document.getElementById('seek-step');
  if(seekStep)seekStep.addEventListener('change',()=>{settings.seekStep=+seekStep.value;saveSettings();});
  const adMute=document.getElementById('ad-mute');
  if(adMute)adMute.addEventListener('change',()=>{
    settings.adMute=adMute.checked;saveSettings();
    if(!settings.adMute&&adMuted&&player){player.setVolume((+volumeEl.value)/100);adMuted=false;}
  });
  const autoSkip=document.getElementById('auto-skip');
  if(autoSkip)autoSkip.addEventListener('change',()=>{settings.autoSkipShort=autoSkip.checked;saveSettings();});
  const shortcuts=document.getElementById('shortcuts');
  if(shortcuts)shortcuts.addEventListener('change',()=>{settings.shortcuts=shortcuts.checked;saveSettings();});
}

function openSettings(tab){
  activePlaylistId=null;setActiveNav('settings');renderSidebar();
  if(tab)settingsTab=tab;
  drawSettings();closeSidebar();
}

function signOut(){
  if(!confirm('Sign out?'))return;
  try{if(player)player.disconnect();}catch(e){}
  if(pollTimer){clearInterval(pollTimer);pollTimer=null;}
  player=null;deviceId=null;sdkReady=false;appIsShown=false;
  accessToken=null;tokenExpiresAt=0;
  currentUserId=null;currentUserProfile=null;
  clearCaches();plMembership.clear();
  localStorage.removeItem('spotify_refresh_token');
  sessionStorage.removeItem('pkce_verifier');
  window.location.href='https://accounts.spotify.com/en/logout';
}

function showApp(){
  loginEl.style.display='none';
  appEl.style.display='grid';
  appIsShown=true;
  tryInitPlayer();
}

async function bootApp(){
  try{
    mainEl.innerHTML='<div class="loading-msg">Loading…</div>';
    const [profile,playlists]=await Promise.all([fetchUserProfile(),fetchPlaylists()]);
    currentUserProfile=profile;
    currentUserId=profile&&profile.id?profile.id:null;
    userPlaylists=playlists;
    renderUserFooter();renderSidebar();renderHome();
  }catch(e){
    mainEl.innerHTML='<div class="empty-msg">Could not load your library. Try reloading. ('+(e.message||'')+')</div>';
    showToast(e.message||'Failed to load library');
  }
}

$('login-btn').addEventListener('click',startLogin);
$('home-btn').addEventListener('click',()=>{renderHome();closeSidebar();});
$('search-btn').addEventListener('click',()=>{renderSearchView();closeSidebar();});
$('settings-btn').addEventListener('click',()=>openSettings());
signoutBtn.addEventListener('click',signOut);
mobileMenuBtn.addEventListener('click',toggleSidebar);
sidebarBackdrop.addEventListener('click',closeSidebar);

$('queue-btn').addEventListener('click',()=>{
  if(queueDrawer.classList.contains('open'))queueDrawer.classList.remove('open');
  else openQueue();
});
$('queue-close').addEventListener('click',()=>queueDrawer.classList.remove('open'));

fxToggle.addEventListener('click',()=>{
  const open=fxPanel.style.display!=='none';
  fxPanel.style.display=open?'none':'block';
  fxToggle.classList.toggle('active',!open);
});
$('fx-close').addEventListener('click',()=>{fxPanel.style.display='none';fxToggle.classList.remove('active');});
$('fx-reset').addEventListener('click',()=>{setPitch(1.0);setBass(0);});
pitchSlider.addEventListener('input',()=>{setPitch((+pitchSlider.value)/100);});
$('pitch-down').addEventListener('click',()=>{setPitch(Math.max(0.5,Math.round((currentPitch-0.05)*100)/100));});
$('pitch-up').addEventListener('click',()=>{setPitch(Math.min(1.5,Math.round((currentPitch+0.05)*100)/100));});
bassSlider.addEventListener('input',()=>{setBass(+bassSlider.value);});
$('bass-down').addEventListener('click',()=>{setBass(Math.max(-12,currentBass-1));});
$('bass-up').addEventListener('click',()=>{setBass(Math.min(12,currentBass+1));});

playBtn.addEventListener('click',()=>{if(!player)return;if(isPaused)player.resume();else player.pause();});
prevBtn.addEventListener('click',()=>player&&player.previousTrack());
nextBtn.addEventListener('click',()=>player&&player.nextTrack());

seekEl.addEventListener('input',()=>{
  seekDragging=true;paintRange(seekEl);
  timeCurrentEl.textContent=formatTime(currentDuration*(seekEl.value/1000));
});
seekEl.addEventListener('change',async()=>{
  const pos=Math.floor(currentDuration*(seekEl.value/1000));
  seekDragging=false;
  if(player)await player.seek(pos);
});

volumeEl.addEventListener('input',()=>{
  paintRange(volumeEl);
  if(player&&!adMuted)player.setVolume(volumeEl.value/100);
});

document.addEventListener('keydown',e=>{
  if(!settings.shortcuts)return;
  const tag=(e.target&&e.target.tagName)||'';
  if(tag==='INPUT'||tag==='TEXTAREA'||tag==='SELECT')return;
  if(e.key==='Escape'){
    fxPanel.style.display='none';fxToggle.classList.remove('active');
    queueDrawer.classList.remove('open');
    document.querySelectorAll('.add-popover').forEach(el=>el.remove());
    closeSidebar();return;
  }
  if(!player)return;
  if(e.key===' '||e.code==='Space'){e.preventDefault();if(isPaused)player.resume();else player.pause();}
  else if(e.key==='ArrowLeft')player.seek(Math.max(0,currentPosition-settings.seekStep*1000));
  else if(e.key==='ArrowRight')player.seek(Math.min(currentDuration,currentPosition+settings.seekStep*1000));
  else if(e.key==='n'||e.key==='N')player.nextTrack();
  else if(e.key==='p'||e.key==='P')player.previousTrack();
  else if(e.key==='f'||e.key==='F')fxToggle.click();
  else if(e.key==='q'||e.key==='Q')$('queue-btn').click();
});

let resizeTimer=null;
function handleResize(){clearTimeout(resizeTimer);resizeTimer=setTimeout(()=>{detectDevice();},120);}
window.addEventListener('resize',handleResize,{passive:true});
window.addEventListener('orientationchange',()=>setTimeout(detectDevice,250),{passive:true});
if(window.visualViewport){window.visualViewport.addEventListener('resize',handleResize,{passive:true});}

paintRange(seekEl);paintRange(volumeEl);paintRange(pitchSlider);paintRange(bassSlider);
pitchValueEl.textContent='1.00×';bassValueEl.textContent='+0 dB';
updateFxStatus();
detectDevice();

if(window.__sdkReady)window.__bootstrap();

(async function boot(){
  try{
    await refreshThemes();
    detectDevice();

    if(IS_FILE){
      document.getElementById('file-warning').style.display='block';
      return;
    }

    const params=new URLSearchParams(window.location.search);
    const code=params.get('code');
    const error=params.get('error');

    if(error){
      window.history.replaceState({},document.title,window.location.pathname);
      showToast('Spotify authorization was denied.');
      return;
    }

    if(code){
      window.history.replaceState({},document.title,window.location.pathname);
      try{
        await exchangeCode(code);
        clearCaches();showApp();
        await bootApp();
      }catch(e){
        console.error('[sc] sign-in failed:',e);
        showToast('Sign-in failed: '+e.message);
      }
      return;
    }

    if(localStorage.getItem('spotify_refresh_token')){
      if(await refreshAccessToken()){
        showApp();
        await bootApp();
        return;
      }
      localStorage.removeItem('spotify_refresh_token');
    }
  }catch(e){
    console.error('[sc] boot error:',e);
    showToast('Startup error: '+(e.message||'unknown'),8000);
  }
})();
