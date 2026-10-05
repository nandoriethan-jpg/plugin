#!/usr/bin/env bash
# Prepare cette machine comme appareil principal pour Claude Code :
# Playwright, Firecrawl et Perplexity disponibles dans toutes les sessions et
# tous les projets.
#
# Methode : les serveurs sont declares en scope utilisateur (~/.claude.json) et
# referencent leurs cles par ${VARIABLE}. Les valeurs sont posees dans le bloc
# env de ~/.claude/settings.json, que Claude Code lit lui-meme au demarrage.
# Aucun profil de shell n'est touche, donc cela vaut aussi pour l'app desktop.
#
# Usage :
#   FIRECRAWL_API_KEY=... PERPLEXITY_API_KEY=... ./scripts/setup-mcp-global.sh
# ou, si un fichier .env existe a la racine du depot, il est lu automatiquement.
#
# Options :
#   --no-verify   ne pas lancer "claude mcp list" a la fin

set -euo pipefail

cd "$(dirname "$0")/.."

verify=1
for arg in "$@"; do
  case "$arg" in
    --no-verify) verify=0 ;;
    *) echo "Option inconnue : $arg" >&2; exit 2 ;;
  esac
done

echo "== Verifications prealables"

if ! command -v python3 >/dev/null; then
  echo "python3 est requis par ce script." >&2
  exit 1
fi
echo "  python3 : $(python3 --version 2>&1)"

if ! command -v node >/dev/null || ! command -v npx >/dev/null; then
  cat >&2 <<'MSG'
  node et npx sont requis : les trois serveurs MCP sont lances par npx.
  Installe Node.js 18 ou plus recent, puis relance.
MSG
  exit 1
fi
echo "  node    : $(node --version)"

if ! command -v claude >/dev/null; then
  cat >&2 <<'MSG'

  Claude Code n'est pas sur le PATH. Installe-le puis relance ce script :

    curl -fsSL https://claude.ai/install.sh | bash

  Ou via npm :

    npm install -g @anthropic-ai/claude-code

MSG
  exit 1
fi
echo "  claude  : $(claude --version 2>&1 | head -1)"

if [ -f .env ]; then
  echo "  lecture de .env"
  set -a; . ./.env; set +a
fi

missing=0
for v in FIRECRAWL_API_KEY PERPLEXITY_API_KEY; do
  if [ -z "${!v:-}" ]; then echo "  variable manquante : $v" >&2; missing=1; fi
done
if [ "$missing" -ne 0 ]; then
  echo >&2
  echo "  Renseigne les variables puis relance. Voir .env.example." >&2
  exit 1
fi
echo "  les 2 cles sont presentes"

echo
echo "== Ecriture de la configuration"

python3 - <<'PY'
import json, os, pathlib, sys

home = pathlib.Path.home()
cfg_dir = home / ".claude"
cfg_dir.mkdir(exist_ok=True)

def load(path):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return {}
    except json.JSONDecodeError:
        sys.exit(f"  {path} contient du JSON invalide. Corrige-le avant de relancer.")

# 1. Les cles dans le bloc env des reglages utilisateur, en fusion.
settings_path = cfg_dir / "settings.json"
settings = load(settings_path)
settings.setdefault("env", {})
for var in ("FIRECRAWL_API_KEY", "PERPLEXITY_API_KEY"):
    settings["env"][var] = os.environ[var]
settings_path.write_text(json.dumps(settings, indent=2) + "\n")
settings_path.chmod(0o600)
print(f"  {settings_path} : cles dans env, permissions 600")

# 2. Les serveurs en scope utilisateur, referencant ces variables.
main_path = home / ".claude.json"
main = load(main_path)
main.setdefault("mcpServers", {})
main["mcpServers"].update({
    "playwright": {
        "type": "stdio", "command": "npx",
        "args": ["-y", "@playwright/mcp@latest"], "env": {},
    },
    "firecrawl": {
        "type": "stdio", "command": "npx",
        "args": ["-y", "firecrawl-mcp"],
        "env": {"FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY}"},
    },
    "perplexity": {
        "type": "stdio", "command": "npx",
        "args": ["-y", "@perplexity-ai/mcp-server"],
        "env": {"PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY}"},
    },
})
main_path.write_text(json.dumps(main, indent=2) + "\n")
print(f"  {main_path} : 3 serveurs en scope utilisateur")
PY

if [ "$verify" -eq 1 ]; then
  echo
  echo "== Verification (le premier lancement telecharge les paquets, soyez patient)"
  env -u FIRECRAWL_API_KEY -u PERPLEXITY_API_KEY claude mcp list || true
fi

cat <<'MSG'

== Termine
Redemarre Claude Code pour que les serveurs soient actifs dans la session.
Ils sont desormais disponibles depuis n'importe quel dossier.

Playwright a besoin d'un navigateur : npx playwright install chromium
MSG
