*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent}
:root{
  --bg-base:#000000;--bg-elevated:#121212;--bg-card:#181818;--bg-hover:#282828;
  --text-base:#ffffff;--text-subdued:#a7a7a7;
  --brand:#1DB954;--brand-hover:#1ed760;--danger:#ff4757;
  --radius:8px;--sidebar-w:280px;--player-h:96px;
  --bg-blur:60px;--bg-alpha:0.6;--bg-dim:0.55;
  --sat:env(safe-area-inset-top,0px);
  --sab:env(safe-area-inset-bottom,0px);
  --sal:env(safe-area-inset-left,0px);
  --sar:env(safe-area-inset-right,0px);
  --app-h:100dvh;
}
html{
  font-family:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
  background:var(--bg-base);color:var(--text-base);
  height:100vh;height:100dvh;
  overflow:hidden;-webkit-font-smoothing:antialiased;
  -webkit-text-size-adjust:100%;text-size-adjust:100%;
}
body{
  font-family:inherit;background:var(--bg-base);color:var(--text-base);
  height:100vh;height:100dvh;overflow:hidden;
  font-size:15px;line-height:1.5;
}
button{font-family:inherit;cursor:pointer;border:none;background:none;color:inherit}
img{display:block;max-width:100%}
input,select,textarea{font-family:inherit;font-size:16px}
::-webkit-scrollbar{width:12px;height:12px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:rgba(255,255,255,0.15);border-radius:6px;border:3px solid transparent;background-clip:content-box}
::-webkit-scrollbar-thumb:hover{background:rgba(255,255,255,0.3);background-clip:content-box}

body.is-touch .track-row{padding:11px 16px}
body.is-touch .track-add-btn{opacity:1;width:36px;height:36px}
body.is-touch .ctrl-btn{width:44px;height:44px}
body.is-touch .mini-btn{width:40px;height:40px}
body.is-touch .nav-item{padding:13px 12px}
body.is-touch .playlist-item{padding:10px 12px}
body.is-touch input[type=range]{height:22px;padding-top:9px;padding-bottom:9px}
body.is-touch input[type=range]::-webkit-slider-thumb{width:16px;height:16px;margin-top:-6px}
body.is-touch .switch{width:48px;height:28px}
body.is-touch .switch span:before{width:22px;height:22px}
body.is-touch .switch input:checked+span:before{transform:translateX(20px)}

.bg-layer{position:fixed;inset:-12%;z-index:-3;background-position:center;background-size:cover;filter:blur(var(--bg-blur)) saturate(1.2);opacity:0;transition:opacity .6s ease;pointer-events:none}
.bg-layer.on{opacity:var(--bg-alpha)}
.bg-dim{position:fixed;inset:0;z-index:-2;background:var(--bg-base);opacity:var(--bg-dim);pointer-events:none;transition:opacity .4s ease,background .4s ease}

.login{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:24px;padding:var(--sat) 20px var(--sab);background:radial-gradient(ellipse at top,rgba(29,185,84,0.18) 0%,var(--bg-base) 60%);z-index:10}
.login-logo{display:flex;align-items:center;gap:12px;margin-bottom:24px}
.login-logo svg{width:48px;height:48px;color:var(--brand)}
.login-logo span{font-size:clamp(28px,7vw,42px);font-weight:800;letter-spacing:-0.03em}
.spotify-btn{background:var(--brand);color:#000;padding:16px 40px;border-radius:999px;font-size:16px;font-weight:700;display:inline-flex;align-items:center;gap:12px;transition:background .15s,transform .1s;min-height:52px}
.spotify-btn:hover{background:var(--brand-hover);transform:scale(1.02)}
.spotify-btn:active{transform:scale(.98)}
.premium-note{color:var(--text-subdued);font-size:13px;margin-top:8px;text-align:center;max-width:320px;line-height:1.6}
.premium-note strong{color:var(--text-base);font-weight:700}

#app{
  display:grid;
  grid-template-columns:var(--sidebar-w) 1fr;
  grid-template-rows:1fr var(--player-h);
  gap:8px;
  padding:8px;
  padding-top:max(8px,var(--sat));
  padding-bottom:max(8px,var(--sab));
  padding-left:max(8px,var(--sal));
  padding-right:max(8px,var(--sar));
  height:100vh;height:100dvh;
  min-height:0;
  min-width:0;
}
.sidebar,.main{
  background:var(--bg-elevated);border-radius:var(--radius);
  overflow:hidden;min-width:0;min-height:0;
}
.player{
  grid-column:1/3;background:var(--bg-elevated);border-radius:var(--radius);
  min-width:0;position:relative;height:100%;
}
@supports (background:color-mix(in srgb,red,blue)){
  .sidebar,.main{background:color-mix(in srgb,var(--bg-elevated) 86%,transparent);backdrop-filter:blur(24px) saturate(1.15)}
  .player{background:color-mix(in srgb,var(--bg-elevated) 90%,transparent);backdrop-filter:blur(24px) saturate(1.15)}
}

.sidebar{display:flex;flex-direction:column;padding:12px 8px}
.sidebar-logo{display:flex;align-items:center;gap:10px;padding:8px 12px 16px}
.sidebar-logo svg{width:28px;height:28px;color:var(--brand);flex-shrink:0}
.sidebar-logo span{font-size:20px;font-weight:800;letter-spacing:-0.02em;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.nav-item{display:flex;align-items:center;gap:12px;padding:10px 12px;border-radius:6px;color:var(--text-subdued);font-size:14px;font-weight:700;cursor:pointer;transition:color .15s,background .15s;flex-shrink:0;min-height:44px}
.nav-item:hover{color:var(--text-base)}
.nav-item.active{color:var(--text-base);background:var(--bg-hover)}
.nav-item svg{width:20px;height:20px;flex-shrink:0}
.library-title{color:var(--text-subdued);font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;padding:18px 12px 10px;flex-shrink:0}
.playlist-list{flex:1;overflow-y:auto;margin-top:2px;min-height:0;overscroll-behavior:contain}
.playlist-item{display:flex;align-items:center;gap:12px;padding:8px 12px;border-radius:6px;cursor:pointer;transition:background .15s;min-width:0;min-height:56px}
.playlist-item:hover,.playlist-item.active{background:var(--bg-hover)}
.playlist-item-thumb{width:40px;height:40px;border-radius:4px;background:#333;flex-shrink:0;overflow:hidden;display:grid;place-items:center;color:#666}
.playlist-item-thumb img{width:100%;height:100%;object-fit:cover}
.playlist-item-thumb svg{width:18px;height:18px}
.playlist-item-info{flex:1;min-width:0}
.playlist-name{font-size:14px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.playlist-meta{font-size:12px;color:var(--text-subdued);margin-top:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

.sidebar-footer{flex-shrink:0;padding:10px 4px 4px;border-top:1px solid rgba(255,255,255,.06);margin-top:8px}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:8px 8px;border-radius:6px}
.sidebar-user-avatar{width:28px;height:28px;border-radius:50%;background:rgba(255,255,255,.08);display:grid;place-items:center;color:var(--text-subdued);flex-shrink:0;overflow:hidden;font-weight:700;font-size:12px}
.sidebar-user-avatar img{width:100%;height:100%;object-fit:cover}
.sidebar-user-name{flex:1;min-width:0;font-size:12.5px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:var(--text-subdued)}
.signout-btn{padding:6px 10px;border-radius:6px;background:transparent;border:1px solid rgba(255,255,255,.12);color:var(--text-subdued);font-size:11.5px;font-weight:700;transition:all .15s;flex-shrink:0}
.signout-btn:hover{color:var(--danger);border-color:rgba(255,71,87,.4);background:rgba(255,71,87,.08)}

.main{overflow-y:auto;overflow-x:hidden;overscroll-behavior:contain;-webkit-overflow-scrolling:touch}
.home{padding:24px}
.home h1{font-size:clamp(22px,3vw,28px);font-weight:800;letter-spacing:-.02em;margin-bottom:20px}
.playlist-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:16px}
.playlist-card{background:var(--bg-card);border-radius:var(--radius);padding:14px;cursor:pointer;transition:background .3s;position:relative;min-width:0}
.playlist-card:hover{background:var(--bg-hover)}
.playlist-card .cover-wrap{position:relative;margin-bottom:12px;width:100%;aspect-ratio:1;border-radius:6px;overflow:hidden;box-shadow:0 8px 24px rgba(0,0,0,.5);background:linear-gradient(135deg,#333,#222);display:grid;place-items:center;color:#666}
.playlist-card .cover-wrap img{width:100%;height:100%;object-fit:cover}
.playlist-card .cover-wrap>svg{width:40px;height:40px}
.playlist-card .play-fab{position:absolute;right:8px;bottom:8px;width:48px;height:48px;border-radius:50%;background:var(--brand);color:#000;display:grid;place-items:center;opacity:0;transform:translateY(8px);transition:opacity .2s,transform .2s,background .15s;box-shadow:0 8px 16px rgba(0,0,0,.4);z-index:2}
.playlist-card:hover .play-fab{opacity:1;transform:translateY(0)}
body.is-touch .playlist-card .play-fab{opacity:1;transform:translateY(0)}
.playlist-card .play-fab:hover{background:var(--brand-hover)}
.playlist-card .play-fab svg{width:20px;height:20px;fill:#000}
.card-name{font-size:14px;font-weight:700;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-bottom:4px}
.card-desc{font-size:12px;color:var(--text-subdued);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

.search-view{padding:24px}
.search-view h1{font-size:clamp(22px,3vw,28px);font-weight:800;letter-spacing:-.02em;margin-bottom:20px}
.search-input{width:100%;max-width:520px;padding:14px 22px;border-radius:500px;border:2px solid transparent;background:var(--bg-card);color:var(--text-base);font-size:16px;outline:none;margin-bottom:20px;transition:background .15s,border-color .15s;min-height:50px}
.search-input:focus{background:var(--bg-hover);border-color:var(--text-base)}
.search-input::placeholder{color:var(--text-subdued)}
.search-toolbar{display:flex;align-items:center;gap:12px;margin-bottom:16px;flex-wrap:wrap}
.ghost-pill{padding:8px 16px;border-radius:999px;border:1px solid rgba(255,255,255,.25);font-size:13px;font-weight:700;color:var(--text-base);transition:all .15s;min-height:36px}
.ghost-pill:hover{background:rgba(255,255,255,.08);border-color:var(--text-base);transform:scale(1.02)}

.tracklist-head,.search-results-head{display:grid;grid-template-columns:36px 40px minmax(0,2fr) minmax(0,1.4fr) 60px 40px;gap:16px;padding:8px 16px;border-bottom:1px solid rgba(255,255,255,.1);color:var(--text-subdued);font-size:12px;font-weight:600;letter-spacing:.05em;text-transform:uppercase;margin-bottom:8px}
.track-row{display:grid;grid-template-columns:36px 40px minmax(0,2fr) minmax(0,1.4fr) 60px 40px;gap:16px;align-items:center;padding:8px 16px;border-radius:6px;cursor:pointer;color:var(--text-subdued);min-width:0;transition:background .1s}
.track-row:hover{background:rgba(255,255,255,.08);color:var(--text-base)}
.track-row.active .track-name{color:var(--brand)}
.track-row .num{font-size:16px;font-variant-numeric:tabular-nums;text-align:right;position:relative;height:20px}
.track-row .num .num-text{display:block;line-height:20px}
.track-row .num .play-icon{position:absolute;inset:0;display:none;align-items:center;justify-content:center;fill:var(--text-base)}
.track-row .num .play-icon svg{width:14px;height:14px}
.track-row:hover .num .num-text{display:none}
.track-row:hover .num .play-icon{display:flex}
.track-row .art{width:40px;height:40px;border-radius:4px;background:#333;overflow:hidden;display:grid;place-items:center;color:#666;flex-shrink:0}
.track-row .art img{width:100%;height:100%;object-fit:cover}
.track-row .art svg{width:16px;height:16px}
.track-row .title-cell{min-width:0;overflow:hidden}
.track-name{font-size:15px;color:var(--text-base);font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.track-artist{font-size:13px;color:var(--text-subdued);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-top:2px}
.track-album{font-size:13px;color:var(--text-subdued);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.track-duration{font-size:13px;text-align:right;font-variant-numeric:tabular-nums}
.track-row.active .num .num-text{color:var(--brand)}
.track-add-btn{width:28px;height:28px;border-radius:50%;display:grid;place-items:center;color:var(--text-subdued);transition:all .15s;opacity:0}
.track-row:hover .track-add-btn{opacity:1}
.track-add-btn:hover{color:var(--text-base);background:rgba(255,255,255,.12);transform:scale(1.1)}
.track-add-btn svg{width:16px;height:16px}
body.hide-numbers .track-row .num .num-text{visibility:hidden}
body.density-compact .track-row{padding:3px 16px}
body.density-compact .track-row .art{width:32px;height:32px}
body.density-compact .tracklist-head,body.density-compact .search-results-head,body.density-compact .track-row{grid-template-columns:36px 32px minmax(0,2fr) minmax(0,1.4fr) 60px 40px}
body.density-comfortable .track-row{padding:14px 16px}
body.reduce-motion *{animation:none!important;transition:none!important}

.playlist-view{padding:24px}
.playlist-header{display:flex;align-items:flex-end;gap:24px;margin-bottom:32px;padding-bottom:20px;min-width:0;flex-wrap:wrap}
.playlist-header .ph-big{width:200px;height:200px;border-radius:var(--radius);overflow:hidden;box-shadow:0 12px 40px rgba(0,0,0,.5);background:linear-gradient(135deg,#333,#222);display:grid;place-items:center;color:#666;flex-shrink:0}
.playlist-header .ph-big img{width:100%;height:100%;object-fit:cover}
.playlist-header .ph-big>svg{width:80px;height:80px}
.playlist-header-info{flex:1;min-width:0}
.playlist-type{font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;margin-bottom:8px}
.playlist-title{font-size:clamp(32px,6vw,64px);font-weight:900;letter-spacing:-.03em;line-height:1;margin-bottom:20px;word-break:break-word}
.playlist-desc{font-size:13px;color:var(--text-subdued);margin-bottom:8px;overflow:hidden;text-overflow:ellipsis}
.playlist-desc strong{color:var(--text-base);font-weight:700}
.playlist-actions{display:flex;align-items:center;gap:20px;margin-bottom:24px}
.big-play{width:56px;height:56px;border-radius:50%;background:var(--brand);color:#000;display:grid;place-items:center;transition:background .15s,transform .1s;box-shadow:0 4px 16px rgba(0,0,0,.3);flex-shrink:0}
.big-play:hover{background:var(--brand-hover);transform:scale(1.04)}
.big-play svg{width:24px;height:24px;fill:#000}
.load-more-btn{display:block;margin:24px auto;padding:12px 32px;border-radius:999px;border:1px solid rgba(255,255,255,.3);color:var(--text-base);font-size:14px;font-weight:700;transition:all .15s;min-height:44px}
.load-more-btn:hover{background:rgba(255,255,255,.1);border-color:var(--text-base);transform:scale(1.02)}
.load-more-btn:disabled{opacity:.5;cursor:wait;transform:none}
.loading-msg,.empty-msg{padding:40px 20px;text-align:center;color:var(--text-subdued);font-size:14px}

.player{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,2fr) minmax(0,1fr);align-items:center;padding:0 16px;gap:16px;height:100%;overflow:hidden;min-width:0}
.player-left{display:flex;align-items:center;gap:14px;min-width:0;overflow:hidden}
.now-cover{width:56px;height:56px;border-radius:4px;background:#222;display:grid;place-items:center;color:#555;flex-shrink:0;overflow:hidden}
.now-cover img{width:100%;height:100%;object-fit:cover}
.now-cover svg{width:22px;height:22px}
.now-info{min-width:0;overflow:hidden}
.now-title{font-size:14px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.now-artist{font-size:12px;color:var(--text-subdued);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-top:2px}
.player-center{display:flex;flex-direction:column;align-items:center;gap:6px;min-width:0;width:100%}
.controls{display:flex;align-items:center;gap:12px}
.ctrl-btn{width:32px;height:32px;border-radius:50%;display:grid;place-items:center;color:var(--text-subdued);transition:color .15s,transform .1s,background .15s;flex-shrink:0}
.ctrl-btn:hover{color:var(--text-base)}
.ctrl-btn svg{width:18px;height:18px;fill:currentColor}
.ctrl-btn.play{width:36px;height:36px;background:var(--text-base);color:#000}
.ctrl-btn.play:hover{transform:scale(1.05);background:#fff}
.ctrl-btn.play svg{width:16px;height:16px}
.progress-row{display:flex;align-items:center;gap:8px;width:100%;max-width:600px;font-size:11px;color:var(--text-subdued);font-variant-numeric:tabular-nums}
.progress-row span{min-width:34px;text-align:center;flex-shrink:0}
.player-right{display:flex;align-items:center;justify-content:flex-end;gap:10px;color:var(--text-subdued);min-width:0}
.player-right>svg{width:16px;height:16px;flex-shrink:0}
.player-right input[type=range]{max-width:100px}
.mini-btn{width:32px;height:32px;border-radius:8px;display:grid;place-items:center;color:var(--text-subdued);transition:all .15s;border:1px solid transparent;flex-shrink:0}
.mini-btn:hover{color:var(--text-base);background:rgba(255,255,255,.08)}
.mini-btn.active{color:var(--brand);background:rgba(255,255,255,.08);border-color:color-mix(in srgb,var(--brand) 45%,transparent)}
.mini-btn svg{width:18px;height:18px}

input[type=range]{-webkit-appearance:none;appearance:none;height:4px;border-radius:2px;cursor:pointer;flex:1;min-width:0;--pct:0%;background:linear-gradient(to right,#fff 0%,#fff var(--pct),rgba(255,255,255,.2) var(--pct),rgba(255,255,255,.2) 100%);touch-action:pan-y}
input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:12px;height:12px;border-radius:50%;background:#fff;opacity:0;transition:opacity .15s;margin-top:-4px}
input[type=range]:hover::-webkit-slider-thumb,input[type=range]:active::-webkit-slider-thumb{opacity:1}
input[type=range]::-moz-range-thumb{width:12px;height:12px;border:none;border-radius:50%;background:#fff}
input[type=range]:hover{background:linear-gradient(to right,var(--brand) 0%,var(--brand) var(--pct),rgba(255,255,255,.2) var(--pct),rgba(255,255,255,.2) 100%)}

.fx-panel{position:absolute;bottom:100%;right:16px;width:340px;max-width:calc(100vw - 32px);max-height:calc(100vh - var(--player-h) - 40px);background:var(--bg-card);border:1px solid rgba(255,255,255,.1);border-radius:14px;padding:20px;margin-bottom:10px;box-shadow:0 16px 48px rgba(0,0,0,.7);z-index:50;overflow-y:auto;overscroll-behavior:contain}
.fx-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px}
.fx-title{font-size:16px;font-weight:700}
.fx-status{font-size:11px;padding:4px 10px;border-radius:999px;background:rgba(255,255,255,.08);color:var(--text-subdued);flex-shrink:0}
.fx-status.active{background:rgba(29,185,84,.2);color:var(--brand)}
.fx-status.warn{background:rgba(255,193,7,.15);color:#ffc107}
.fx-status.error{background:rgba(255,71,87,.15);color:var(--danger)}
.fx-control{margin-bottom:18px}
.fx-row{display:flex;align-items:center;justify-content:space-between;margin-bottom:8px}
.fx-label{font-size:13px;font-weight:600}
.fx-value{font-size:12px;color:var(--text-subdued);font-variant-numeric:tabular-nums;font-weight:500}
.fx-slider-wrap{display:flex;align-items:center;gap:8px}
.fx-step-btn{width:28px;height:28px;border-radius:50%;display:grid;place-items:center;background:rgba(255,255,255,.1);color:var(--text-subdued);font-size:16px;line-height:1;transition:all .15s;flex-shrink:0}
.fx-step-btn:hover{background:rgba(255,255,255,.2);color:var(--text-base)}
.fx-help{font-size:11px;color:var(--text-subdued);line-height:1.5;margin-top:6px;padding:8px 10px;background:rgba(255,255,255,.03);border-radius:6px;border-left:2px solid rgba(255,255,255,.15)}
.fx-actions{display:flex;gap:8px;margin-top:18px;padding-top:18px;border-top:1px solid rgba(255,255,255,.1)}
.fx-action{flex:1;padding:10px;border-radius:8px;font-size:13px;font-weight:700;text-align:center;transition:all .15s;min-height:40px}
.fx-action.primary{background:var(--brand);color:#000}
.fx-action.primary:hover{background:var(--brand-hover)}
.fx-action.secondary{background:rgba(255,255,255,.1);color:var(--text-base)}
.fx-action.secondary:hover{background:rgba(255,255,255,.18)}

.add-popover{position:fixed;width:340px;max-width:calc(100vw - 24px);max-height:min(480px,70vh);background:var(--bg-card);border-radius:12px;box-shadow:0 16px 48px rgba(0,0,0,.75);z-index:400;display:flex;flex-direction:column;overflow:hidden;border:1px solid rgba(255,255,255,.08)}
.add-popover-header{padding:14px 16px 4px;font-size:15px;font-weight:800;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.add-popover-status{padding:0 16px 10px;font-size:11.5px;color:var(--text-subdued)}
.add-popover-warning{margin:0 12px 10px;padding:10px 12px;border-radius:8px;background:rgba(255,71,87,.08);border-left:3px solid var(--danger);font-size:12px;color:#ffb3b8;line-height:1.5;display:none}
.add-popover-warning.show{display:block}
.add-popover-warning button{margin-top:8px;padding:6px 12px;border-radius:6px;background:var(--danger);color:#fff;font-size:12px;font-weight:700;display:inline-block}
.add-filter{margin:0 12px 8px;padding:10px 12px;border-radius:8px;border:none;background:rgba(255,255,255,.07);color:var(--text-base);font-size:16px;outline:none}
.add-filter::placeholder{color:var(--text-subdued)}
.add-popover-list{flex:1;overflow-y:auto;padding:0 6px 6px;min-height:0;overscroll-behavior:contain}
.add-row{display:flex;align-items:center;gap:10px;width:100%;padding:8px 10px;border-radius:8px;text-align:left;transition:background .12s,transform .12s;color:var(--text-base);min-height:52px;position:relative}
.add-row:hover{background:rgba(255,255,255,.08)}
.add-row.in{background:rgba(29,185,84,.07)}
.add-row.in:hover{background:rgba(255,71,87,.10)}
.add-thumb{width:36px;height:36px;border-radius:4px;background:#333;flex-shrink:0;overflow:hidden;display:grid;place-items:center;color:#666}
.add-thumb img{width:100%;height:100%;object-fit:cover}
.add-thumb svg{width:16px;height:16px}
.add-info{flex:1;min-width:0}
.add-name{font-size:13.5px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.add-meta{font-size:11.5px;color:var(--text-subdued);margin-top:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.add-state{width:32px;height:32px;display:grid;place-items:center;flex-shrink:0;color:var(--text-subdued);border-radius:50%;transition:all .15s;cursor:pointer}
.add-row.in .add-state{color:var(--brand);background:rgba(29,185,84,.12)}
.add-row.in:hover .add-state{color:var(--danger);background:rgba(255,71,87,.15);transform:scale(1.08)}
.add-row:not(.in):hover .add-state{color:var(--brand);background:rgba(29,185,84,.12);transform:scale(1.08)}
.add-state svg{width:16px;height:16px}
.add-row.just-changed{animation:pulseRow .4s ease}
@keyframes pulseRow{0%{transform:scale(1)}50%{transform:scale(1.015)}100%{transform:scale(1)}}
.add-popover-new{display:flex;align-items:center;gap:10px;padding:13px 16px;border-top:1px solid rgba(255,255,255,.08);font-size:13.5px;font-weight:700;color:var(--brand);text-align:left;transition:background .12s}
.add-popover-new:hover{background:rgba(29,185,84,.1)}
.add-popover-new svg{width:16px;height:16px}
.add-popover-empty{padding:18px 16px;text-align:center;font-size:12.5px;color:var(--text-subdued);line-height:1.6}
.mini-spinner{width:13px;height:13px;border:2px solid rgba(255,255,255,.2);border-top-color:var(--brand);border-radius:50%;display:inline-block;animation:spin .7s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}

.queue-drawer{position:fixed;top:max(8px,var(--sat));right:max(8px,var(--sar));bottom:calc(var(--player-h) + 16px + max(8px,var(--sab)));width:340px;max-width:calc(100vw - 16px);z-index:70;background:var(--bg-elevated);border-radius:var(--radius);display:flex;flex-direction:column;overflow:hidden;transform:translateX(calc(100% + 24px));transition:transform .3s cubic-bezier(.22,1,.36,1);box-shadow:-12px 0 48px rgba(0,0,0,.55);min-height:0}
.queue-drawer.open{transform:translateX(0)}
@supports (background:color-mix(in srgb,red,blue)){.queue-drawer{background:color-mix(in srgb,var(--bg-elevated) 90%,transparent);backdrop-filter:blur(28px) saturate(1.2)}}
.queue-head{display:flex;align-items:center;justify-content:space-between;padding:16px;flex-shrink:0}
.queue-head h2{font-size:16px;font-weight:800}
.queue-close{width:32px;height:32px;border-radius:50%;display:grid;place-items:center;color:var(--text-subdued)}
.queue-close:hover{background:rgba(255,255,255,.1);color:var(--text-base)}
.queue-close svg{width:16px;height:16px}
.queue-body{flex:1;overflow-y:auto;padding:0 8px 16px;min-height:0;overscroll-behavior:contain}
.queue-label{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--text-subdued);padding:12px 8px 8px}
.queue-item{display:flex;align-items:center;gap:10px;width:100%;padding:8px;border-radius:8px;text-align:left;transition:background .12s;color:var(--text-base);min-height:52px}
.queue-item:hover{background:rgba(255,255,255,.08)}
.queue-thumb{width:38px;height:38px;border-radius:4px;background:#333;overflow:hidden;flex-shrink:0;display:grid;place-items:center;color:#666}
.queue-thumb img{width:100%;height:100%;object-fit:cover}
.queue-thumb svg{width:16px;height:16px}
.queue-info{flex:1;min-width:0}
.queue-name{font-size:13px;font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.queue-artist{font-size:11.5px;color:var(--text-subdued);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-top:2px}

.settings{padding:24px;max-width:1040px}
.settings-head{display:flex;align-items:flex-end;justify-content:space-between;gap:16px;flex-wrap:wrap;margin-bottom:6px}
.settings-head h1{font-size:clamp(22px,3vw,28px);font-weight:800;letter-spacing:-.02em}
.settings-sub{font-size:13px;color:var(--text-subdued);margin-top:4px}
.tabs{display:flex;gap:8px;margin:22px 0;flex-wrap:wrap}
.tab-btn{padding:8px 16px;border-radius:999px;background:rgba(255,255,255,.07);font-size:13px;font-weight:700;color:var(--text-subdued);transition:all .15s;min-height:36px}
.tab-btn:hover{color:var(--text-base);background:rgba(255,255,255,.12)}
.tab-btn.active{background:var(--brand);color:#000}
.theme-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px}
.theme-card{background:var(--bg-card);border:2px solid transparent;border-radius:12px;padding:10px;text-align:left;transition:all .15s;position:relative}
.theme-card:hover{border-color:rgba(255,255,255,.2);transform:translateY(-2px)}
.theme-card.active{border-color:var(--brand);box-shadow:0 0 0 1px var(--brand) inset}
.swatches{display:flex;height:56px;border-radius:8px;overflow:hidden;margin-bottom:10px}
.swatches span{flex:1}
.theme-name{font-size:12.5px;font-weight:700;color:var(--text-base);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.theme-badge{position:absolute;top:14px;right:14px;font-size:9px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;padding:3px 7px;border-radius:5px;background:rgba(29,185,84,.85);color:#000}
.setting-group{background:var(--bg-card);border-radius:12px;padding:6px 18px;margin-bottom:16px}
.setting-row{display:flex;align-items:center;justify-content:space-between;gap:18px;padding:14px 0;border-bottom:1px solid rgba(255,255,255,.06);flex-wrap:wrap}
.setting-row:last-child{border-bottom:none}
.setting-label{font-size:14px;font-weight:600}
.setting-sub{font-size:12px;color:var(--text-subdued);margin-top:3px;max-width:420px;line-height:1.5}
.setting-control{display:flex;align-items:center;gap:12px;flex-shrink:0}
.setting-control input[type=range]{width:160px}
.range-val{font-size:12px;color:var(--text-subdued);font-variant-numeric:tabular-nums;min-width:44px;text-align:right}
.switch{position:relative;width:44px;height:24px;flex-shrink:0;display:inline-block}
.switch input{opacity:0;width:0;height:0;position:absolute}
.switch span{position:absolute;inset:0;background:rgba(255,255,255,.2);border-radius:999px;transition:.2s;cursor:pointer}
.switch span:before{content:'';position:absolute;width:18px;height:18px;left:3px;top:3px;background:#fff;border-radius:50%;transition:.2s}
.switch input:checked+span{background:var(--brand)}
.switch input:checked+span:before{transform:translateX(20px)}
.styled-select{background:rgba(255,255,255,.08);border:none;color:var(--text-base);padding:8px 12px;border-radius:8px;font-size:13px;outline:none;cursor:pointer;min-height:36px}
.styled-select option{background:#1a1a1a;color:#fff}
.text-input{background:rgba(255,255,255,.08);border:1px solid transparent;color:var(--text-base);padding:10px 14px;border-radius:8px;font-size:16px;outline:none;width:100%}
.text-input:focus{border-color:var(--brand)}
.btn-solid{padding:10px 18px;border-radius:8px;background:var(--brand);color:#000;font-size:13px;font-weight:700;transition:background .15s;flex-shrink:0;min-height:40px}
.btn-solid:hover{background:var(--brand-hover)}
.btn-ghost{padding:10px 18px;border-radius:8px;background:rgba(255,255,255,.08);color:var(--text-base);font-size:13px;font-weight:700;transition:background .15s;flex-shrink:0;min-height:40px}
.btn-ghost:hover{background:rgba(255,255,255,.16)}
.file-input{display:none}
.bg-preview{width:100%;height:150px;border-radius:12px;margin:6px 0 16px;background-size:cover;background-position:center;border:1px solid rgba(255,255,255,.1);display:grid;place-items:center;color:var(--text-subdued);font-size:13px}
.settings-foot{padding:16px 0 40px;font-size:12px;color:var(--text-subdued);line-height:1.6}
.themes-status{background:var(--bg-card);border-radius:12px;padding:14px 18px;margin-bottom:16px;font-size:13px;display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap}
.themes-status.ok{border-left:3px solid var(--brand)}
.themes-status.warn{border-left:3px solid #ffc107}
.themes-status.err{border-left:3px solid var(--danger)}
.themes-status small{font-size:11.5px;color:var(--text-subdued);display:block;margin-top:3px;line-height:1.5}
.themes-empty{padding:32px 20px;text-align:center;color:var(--text-subdued);font-size:14px;line-height:1.8}
.themes-empty code{background:rgba(255,255,255,.08);padding:2px 8px;border-radius:5px;font-family:'SF Mono',ui-monospace,Monaco,Consolas,monospace;font-size:12px;color:var(--text-base)}
.themes-empty ol{text-align:left;max-width:560px;margin:16px auto;padding-left:24px}
.themes-empty ol li{margin-bottom:8px}

.toast{position:fixed;bottom:calc(var(--player-h) + 20px + var(--sab));left:50%;transform:translateX(-50%) translateY(20px);background:var(--danger);color:#fff;padding:12px 20px;border-radius:8px;font-size:13px;font-weight:600;opacity:0;pointer-events:none;transition:opacity .25s,transform .25s;z-index:500;max-width:90vw;text-align:center;box-shadow:0 8px 24px rgba(0,0,0,.5)}
.toast.show{opacity:1;transform:translateX(-50%) translateY(0)}
.toast.success{background:var(--brand);color:#000}

.mobile-menu-btn{display:none;position:fixed;top:max(16px,calc(var(--sat) + 8px));left:max(16px,calc(var(--sal) + 8px));z-index:65;width:44px;height:44px;border-radius:50%;background:var(--bg-card);color:var(--text-base);border:1px solid rgba(255,255,255,.12);align-items:center;justify-content:center;box-shadow:0 4px 12px rgba(0,0,0,.4);transition:transform .15s}
.mobile-menu-btn:active{transform:scale(.94)}
.mobile-menu-btn svg{width:22px;height:22px}
.sidebar-backdrop{display:none;position:fixed;inset:0;background:rgba(0,0,0,.65);z-index:55;opacity:0;pointer-events:none;transition:opacity .25s;backdrop-filter:blur(2px)}
.sidebar-backdrop.show{opacity:1;pointer-events:auto}

body[data-device="tablet"]{--player-h:108px;--sidebar-w:76px}
body[data-device="tablet"] .sidebar-logo span,
body[data-device="tablet"] .nav-item span,
body[data-device="tablet"] .library-title,
body[data-device="tablet"] .playlist-name,
body[data-device="tablet"] .playlist-meta,
body[data-device="tablet"] .sidebar-user-name{display:none}
body[data-device="tablet"] .sidebar-logo{justify-content:center;padding:8px 0 16px}
body[data-device="tablet"] .nav-item{justify-content:center;padding:12px 0}
body[data-device="tablet"] .playlist-item{justify-content:center;padding:8px 0;min-height:52px}
body[data-device="tablet"] .playlist-item-info{display:none}
body[data-device="tablet"] .sidebar-user{justify-content:center}
body[data-device="tablet"] .signout-btn{display:none}
body[data-device="tablet"] .home,
body[data-device="tablet"] .search-view,
body[data-device="tablet"] .playlist-view,
body[data-device="tablet"] .settings{padding:20px}

body[data-device="mobile"]{--player-h:152px;--sidebar-w:0}
body[data-device="mobile"] #app{grid-template-columns:1fr;grid-template-rows:1fr var(--player-h);gap:6px;padding:6px;padding-top:max(6px,var(--sat));padding-bottom:max(6px,var(--sab));padding-left:max(6px,var(--sal));padding-right:max(6px,var(--sar))}
body[data-device="mobile"] .sidebar{position:fixed;top:max(6px,var(--sat));bottom:calc(var(--player-h) + 12px + var(--sab));left:max(6px,var(--sal));width:280px;max-width:calc(100vw - 60px);z-index:60;transform:translateX(calc(-100% - 20px));transition:transform .3s cubic-bezier(.22,1,.36,1);box-shadow:8px 0 32px rgba(0,0,0,.6)}
body[data-device="mobile"] .sidebar.open{transform:translateX(0)}
body[data-device="mobile"] .sidebar-backdrop{display:block}
body[data-device="mobile"] .mobile-menu-btn{display:flex}
body[data-device="mobile"] .player{grid-column:1/2}
body[data-device="mobile"] .player{grid-template-columns:1fr;padding:10px 14px;gap:4px;align-content:center}
body[data-device="mobile"] .player-left{display:flex;justify-content:center;text-align:center;min-height:0}
body[data-device="mobile"] .player-left .now-cover{width:40px;height:40px}
body[data-device="mobile"] .player-right{display:none}
body[data-device="mobile"] .now-title{font-size:13px}
body[data-device="mobile"] .now-artist{font-size:11px}
body[data-device="mobile"] .player-center{gap:4px}
body[data-device="mobile"] .progress-row{font-size:10px}
body[data-device="mobile"] .progress-row span{min-width:30px}
body[data-device="mobile"] .ctrl-btn{width:40px;height:40px}
body[data-device="mobile"] .ctrl-btn.play{width:48px;height:48px}
body[data-device="mobile"] .ctrl-btn.play svg{width:20px;height:20px}
body[data-device="mobile"] .controls{gap:16px}
body[data-device="mobile"] .home,
body[data-device="mobile"] .search-view,
body[data-device="mobile"] .playlist-view,
body[data-device="mobile"] .settings{padding:16px;padding-top:60px}
body[data-device="mobile"] .playlist-grid{grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:12px}
body[data-device="mobile"] .playlist-card{padding:10px}
body[data-device="mobile"] .playlist-card .cover-wrap{margin-bottom:8px}
body[data-device="mobile"] .card-name{font-size:12.5px}
body[data-device="mobile"] .card-desc{font-size:11px}
body[data-device="mobile"] .playlist-header{flex-direction:column;align-items:center;text-align:center;gap:16px;margin-bottom:20px;padding-bottom:12px}
body[data-device="mobile"] .playlist-header .ph-big{width:140px;height:140px}
body[data-device="mobile"] .playlist-title{font-size:28px;margin-bottom:10px}
body[data-device="mobile"] .playlist-actions{justify-content:center}
body[data-device="mobile"] .tracklist-head,
body[data-device="mobile"] .search-results-head{grid-template-columns:28px 40px minmax(0,1fr) 40px;gap:10px;padding:6px 10px;font-size:11px}
body[data-device="mobile"] .tracklist-head > :nth-child(4),
body[data-device="mobile"] .tracklist-head > :nth-child(5),
body[data-device="mobile"] .search-results-head > :nth-child(4),
body[data-device="mobile"] .search-results-head > :nth-child(5){display:none}
body[data-device="mobile"] .track-row{grid-template-columns:28px 40px minmax(0,1fr) 40px;gap:10px;padding:8px 10px}
body[data-device="mobile"] .track-album,
body[data-device="mobile"] .track-duration{display:none}
body[data-device="mobile"] .track-add-btn{opacity:1;width:34px;height:34px}
body[data-device="mobile"] .fx-panel{position:fixed;inset:auto 8px calc(var(--player-h) + 12px + var(--sab)) 8px;width:auto;max-width:none;max-height:70vh;margin-bottom:0}
body[data-device="mobile"] .queue-drawer{left:max(6px,var(--sal));right:max(6px,var(--sar));top:max(6px,var(--sat));bottom:calc(var(--player-h) + 12px + var(--sab));width:auto;max-width:none}
body[data-device="mobile"] .add-popover{left:8px!important;right:8px;width:auto;top:auto!important;bottom:calc(var(--player-h) + 12px + var(--sab));max-height:70vh}
body[data-device="mobile"] .settings-head{flex-direction:column;align-items:flex-start}
body[data-device="mobile"] .theme-grid{grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:10px}
body[data-device="mobile"] .swatches{height:48px}
body[data-device="mobile"] .setting-row{flex-direction:column;align-items:flex-start;gap:10px}
body[data-device="mobile"] .setting-control{width:100%;justify-content:flex-end}
body[data-device="mobile"] .setting-control input[type=range]{width:auto;flex:1}
body[data-device="mobile"] .text-input{flex:1;min-width:0}
body[data-device="mobile"] .search-input{font-size:16px}

body[data-device="mobile"].is-landscape{--player-h:80px}
body[data-device="mobile"].is-landscape #app{grid-template-columns:1fr;grid-template-rows:1fr var(--player-h)}
body[data-device="mobile"].is-landscape .player{grid-template-columns:minmax(0,1fr) minmax(0,1.4fr);padding:6px 14px;gap:12px;align-items:center}
body[data-device="mobile"].is-landscape .player-left{justify-content:flex-start;text-align:left;gap:10px}
body[data-device="mobile"].is-landscape .player-center{gap:2px}
body[data-device="mobile"].is-landscape .controls{gap:10px}
body[data-device="mobile"].is-landscape .ctrl-btn{width:34px;height:34px}
body[data-device="mobile"].is-landscape .ctrl-btn.play{width:40px;height:40px}
body[data-device="mobile"].is-landscape .progress-row{display:none}
body[data-device="mobile"].is-landscape .now-cover{width:44px;height:44px}
body[data-device="mobile"].is-landscape .home,
body[data-device="mobile"].is-landscape .search-view,
body[data-device="mobile"].is-landscape .playlist-view,
body[data-device="mobile"].is-landscape .settings{padding:12px;padding-top:56px}
body[data-device="mobile"].is-landscape .playlist-header{flex-direction:row;align-items:flex-end;text-align:left;gap:16px}
body[data-device="mobile"].is-landscape .playlist-header .ph-big{width:100px;height:100px}
body[data-device="mobile"].is-landscape .playlist-title{font-size:22px}

@media (max-height:500px) and (orientation:landscape){
  :root,body[data-device="mobile"]{--player-h:76px}
  .fx-panel{max-height:calc(100vh - 100px)}
  .toast{bottom:calc(var(--player-h) + 12px)}
}
@media (prefers-reduced-motion:reduce){
  *{animation-duration:0.01ms!important;transition-duration:0.01ms!important}
  }
