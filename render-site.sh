#!/usr/bin/env bash
# Gera o site completo em docs/: versão em inglês (en/) e em português (raiz).
#
# Cada render do Quarto escreve seu próprio índice de busca, sitemap e
# listings.json; aqui renderizamos as duas versões e juntamos esses arquivos
# para que a busca e o sitemap incluam as duas línguas.
set -euo pipefail

QUARTO_PROFILE=en quarto render

tmp="$(mktemp -d)"
for f in search.json sitemap.xml listings.json; do
  [ -f "docs/$f" ] && mv "docs/$f" "$tmp/$f"
done

QUARTO_PROFILE=pt quarto render --no-clean

python3 - "$tmp" <<'PY'
import json, sys, re
from pathlib import Path

tmp, docs = Path(sys.argv[1]), Path("docs")

for name in ["search.json", "listings.json"]:
    extra = tmp / name
    if extra.exists():
        main = docs / name
        merged = (json.loads(main.read_text()) if main.exists() else []) + json.loads(extra.read_text())
        main.write_text(json.dumps(merged, ensure_ascii=False))

extra = tmp / "sitemap.xml"
main = docs / "sitemap.xml"
if extra.exists() and main.exists():
    urls = re.findall(r"<url>.*?</url>", extra.read_text(), flags=re.S)
    text = main.read_text().replace("</urlset>", "\n".join(urls) + "\n</urlset>")
    main.write_text(text)
PY

rm -rf "$tmp"
echo "Site gerado em docs/ (português na raiz, inglês em docs/en/)."
