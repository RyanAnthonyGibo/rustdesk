#!/usr/bin/env bash
# Aplica no fonte OFICIAL do RustDesk (tag 1.5.0) os padrões StarMDM.
# Uso (no runner): RD_HOST=rustdesk.cvtingressos.com.br RD_KEY=<secret> ./patch.sh
set -euo pipefail
: "${RD_HOST:?}"; : "${RD_KEY:?}"
F=libs/hbb_common/src/config.rs
python3 - "$F" <<'PY'
import os,sys,re
f=sys.argv[1]; s=open(f).read()
h=os.environ["RD_HOST"]; k=os.environ["RD_KEY"]
s,n1=re.subn(r'pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\]]*\];', f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{h}"];', s)
s,n2=re.subn(r'pub const RS_PUB_KEY: &str = "[^"]*";', f'pub const RS_PUB_KEY: &str = "{k}";', s)
old='''    let option = keys::OPTION_ALLOW_WEBSOCKET;
    option2bool(option, &Config::get_option(option))'''
new='''    let option = keys::OPTION_ALLOW_WEBSOCKET;
    let v = Config::get_option(option);
    if v.is_empty() { return true; } // StarMDM: WebSocket ligado por padrao
    option2bool(option, &v)'''
n3=s.count(old); s=s.replace(old,new)
assert n1==1 and n2==1 and n3==1, (n1,n2,n3)
open(f,"w").write(s); print("patch ok")
PY
# WebSocket seguro (wss://HOST/ws/id e /ws/relay) pelo tunel Cloudflare quando o servidor e um dominio.
python3 - libs/hbb_common/src/websocket.rs <<'PY'
import sys
f=sys.argv[1]; s=open(f).read()
old='if api_server.starts_with("https") {'
new='if api_server.is_empty() || api_server.starts_with("https") {'
assert s.count(old)==1, "ws patch"
open(f,"w").write(s.replace(old,new)); print("wss patch ok")
PY
# Nome visivel: RyanDesk (pacote e creditos/licenca AGPL inalterados)
sed -i '0,/android:label="RustDesk"/s//android:label="RyanDesk"/; s/android:label="RustDesk Input"/android:label="RyanDesk Input"/' flutter/android/app/src/main/AndroidManifest.xml
sed -i 's#<string name="app_name">RustDesk</string>#<string name="app_name">RyanDesk</string>#' flutter/android/app/src/main/res/values/strings.xml
grep -q 'android:label="RyanDesk"' flutter/android/app/src/main/AndroidManifest.xml && echo "label ok"
