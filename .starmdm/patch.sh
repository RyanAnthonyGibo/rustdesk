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
