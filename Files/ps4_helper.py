#!/usr/bin/env python3
"""Local helper for ps4-games-list.html. Run: python3 ps4_helper.py  (no extra packages needed)
Endpoints (http://127.0.0.1:8787):
  /versions?id=CUSA12345  -> [{"version","key"}...] newest first
  /pieces?key=...&id=...  -> {"urls":[...]}
  /file?url=...           -> streams the file as a download (playstation.net hosts only)"""
import json, re, sys, urllib.request, urllib.parse
from html.parser import HTMLParser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

UA = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36'}
BASE = 'https://orbispatches.com/'

class Versions(HTMLParser):
    def __init__(self):
        super().__init__(); self.items = []
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'a' and 'main' in (a.get('class') or '').split() and a.get('data-key'):
            self.items.append({'version': a.get('data-version', '?'), 'key': a['data-key']})

def get_versions(cusa):
    req = urllib.request.Request(BASE + cusa, headers=UA)
    html = urllib.request.urlopen(req, timeout=30).read().decode('utf-8', 'replace')
    p = Versions(); p.feed(html)
    return sorted(p.items, key=lambda v: float(re.sub(r'[^0-9.]', '', v['version']) or 0), reverse=True)

def get_pieces(key, cusa):
    data = urllib.parse.urlencode({'key': key}).encode()
    req = urllib.request.Request(BASE + 'api/patch.php', data=data,
        headers={**UA, 'X-Requested-With': 'XMLHttpRequest', 'Referer': BASE + cusa})
    resp = json.loads(urllib.request.urlopen(req, timeout=30).read())
    if not resp.get('success'):
        raise RuntimeError('ORBISPatches refused the request')
    return [p['pkg_url'] for p in resp['pieces']]

class H(BaseHTTPRequestHandler):
    def _json(self, obj, code=200):
        b = json.dumps(obj).encode()
        self.send_response(code); self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*'); self.send_header('Access-Control-Allow-Private-Network', 'true'); self.send_header('Content-Length', str(len(b)))
        self.end_headers(); self.wfile.write(b)
    def do_OPTIONS(self):
        self.send_response(204)
        for k, v in (('Access-Control-Allow-Origin', '*'), ('Access-Control-Allow-Methods', 'GET'),
                     ('Access-Control-Allow-Headers', '*'), ('Access-Control-Allow-Private-Network', 'true')):
            self.send_header(k, v)
        self.end_headers()
    def do_GET(self):
        u = urllib.parse.urlparse(self.path); q = urllib.parse.parse_qs(u.query)
        g = lambda k: (q.get(k) or [''])[0]
        try:
            if u.path == '/versions':
                cusa = g('id').upper()
                if not re.fullmatch(r'CUSA\d{5}', cusa): return self._json({'error': 'bad id'}, 400)
                return self._json(get_versions(cusa))
            if u.path == '/pieces':
                return self._json({'urls': get_pieces(g('key'), g('id').upper())})
            if u.path == '/file':
                url = g('url'); host = urllib.parse.urlparse(url).hostname or ''
                if not host.endswith('playstation.net'): return self._json({'error': 'host not allowed'}, 403)
                r = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60)
                self.send_response(200)
                self.send_header('Content-Type', 'application/octet-stream')
                if r.headers.get('Content-Length'): self.send_header('Content-Length', r.headers['Content-Length'])
                self.send_header('Content-Disposition', 'attachment; filename="%s"' % url.split('/')[-1].split('?')[0])
                self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers()
                while True:
                    c = r.read(1 << 20)
                    if not c: break
                    self.wfile.write(c)
                return
            self._json({'error': 'not found'}, 404)
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            self._json({'error': str(e)}, 502)

if __name__ == '__main__':
    print('Helper running on http://127.0.0.1:8787  (Ctrl+C to stop)')
    ThreadingHTTPServer(('127.0.0.1', 8787), H).serve_forever()
