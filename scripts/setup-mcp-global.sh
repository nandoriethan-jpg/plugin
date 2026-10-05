#!/usr/bin/env bash
# Rend les serveurs MCP Playwright, Firecrawl et Perplexity disponibles dans
# toutes les sessions Claude Code et tous les projets, sur cette machine.
#
# Methode : les serveurs sont declares en scope utilisateur (~/.claude.json) et
# referencent leurs cles par ${VARIABLE}. Les valeurs sont posees dans le bloc
# env de ~/.claude/settings.json, que Claude Code lit lui-meme au demarrage.
# Aucun profil de shell n'est touche, donc cela vaut aussi pour l'app desktop.
#
# Usage :
#   FIRECRAWL_API_KEY=... PERPLEXITY_API_KEY=... ./scripts/setup-mcp-global.sh
# ou, si un fichier .env existe a la racine du depot, il est lu automatiquement.

set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  echo "Lecture de .env"
  set -a; . ./.env; set +a
fi

missing=0
for v in FIRECRAWL_API_KEY PERPLEXITY_API_KEY; do
  if [ -z "${!v:-}" ]; then echo "Variable manquante : $v" >&2; missing=1; fi
done
if [ "$missing" -ne 0 ]; then
  echo "Renseigne les variables puis relance. Voir .env.example." >&2
  exit 1
fi

command -v python3 >/dev/null || { echo "python3 est requis." >&2; exit 1; }

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
        sys.exit(f"{path} contient du JSON invalide. Corrige-le avant de relancer.")

# 1. Les cles dans le bloc env des reglages utilisateur, en fusion.
settings_path = cfg_dir / "settings.json"
settings = load(settings_path)
settings.setdefault("env", {})
for var in ("FIRECRAWL_API_KEY", "PERPLEXITY_API_KEY"):
    settings["env"][var] = os.environ[var]
settings_path.write_text(json.dumps(settings, indent=2) + "\n")
settings_path.chmod(0o600)
print(f"Ecrit {settings_path} (cles dans env, permissions 600)")

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
print(f"Ecrit {main_path} (3 serveurs en scope utilisateur)")
PY

echo
echo "Termine. Redemarre Claude Code, puis verifie avec : claude mcp list"
