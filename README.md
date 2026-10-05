# Configuration des serveurs MCP

Playwright, Firecrawl et Perplexity, disponibles dans toutes les sessions
Claude Code et tous les projets. Les clés ne sont jamais committées.

## La méthode

Deux fichiers travaillent ensemble, et c'est ce qui rend les serveurs
disponibles partout :

| Fichier | Rôle |
| --- | --- |
| `~/.claude.json` | déclare les trois serveurs en scope utilisateur, avec leurs clés référencées par `${VARIABLE}` |
| `~/.claude/settings.json` | donne les valeurs de ces variables dans son bloc `env` |

Claude Code lit lui-même ces deux fichiers au démarrage de chaque session,
quel que soit le dossier courant. Aucun profil de shell n'est modifié, donc la
méthode vaut aussi pour l'application desktop, qui ne lit pas forcément un
`.zshrc` ou un `.bashrc`.

Le scope utilisateur est ce qui donne le « partout ». Un `.mcp.json` de projet
ne vaut que dans ce projet, et les variables exportées à la main dans un shell
ne valent que pour ce shell.

## Installation globale

```bash
cp .env.example .env    # puis remplir les 2 clés
./scripts/setup-mcp-global.sh
```

Le script fusionne dans les fichiers existants au lieu de les écraser, pose
`settings.json` en permissions 600, et refuse de tourner si une clé manque.
Il lit `.env` automatiquement, ou prend les variables de l'environnement.

Redémarrer Claude Code, puis vérifier :

```bash
claude mcp list
```

Les trois serveurs doivent apparaître connectés, depuis n'importe quel dossier.

## Le .mcp.json du dépôt

Ce dépôt déclare aussi les trois serveurs dans `.mcp.json`, avec la même
syntaxe `${VARIABLE}`. C'est redondant avec l'installation globale sur ta
machine, mais utile ailleurs : une session cloud, une autre machine, ou un
collaborateur qui clone le dépôt obtient les serveurs sans rien installer.
Les deux coexistent sans conflit, la config de projet ayant la priorité.

## Session cloud

Les clés doivent être définies comme secrets de l'environnement, et la
politique réseau doit autoriser les hôtes suivants, sinon les serveurs
démarrent mais leurs appels d'API échouent :

| Serveur | Hôte à autoriser |
| --- | --- |
| Firecrawl | `api.firecrawl.dev` |
| Perplexity | `api.perplexity.ai` |
| Playwright | les sites à visiter |

Les deux réglages sont dans les paramètres de l'environnement cloud, menu de
l'environnement dans la barre de titre de la session, puis Edit. Les niveaux
d'accès réseau sont décrits sur
<https://code.claude.com/docs/en/claude-code-on-the-web>.

## Équivalent en commandes

Pour ajouter un serveur à la main. Noter que `-e` attend une paire
`NOM=valeur` : passer la clé seule est refusé.

```bash
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
claude mcp add --scope user firecrawl -e FIRECRAWL_API_KEY=... -- npx -y firecrawl-mcp
claude mcp add --scope user perplexity -e PERPLEXITY_API_KEY=... -- npx -y @perplexity-ai/mcp-server
```

Cette forme inscrit la clé en clair dans `~/.claude.json`. Le script lui
préfère `${VARIABLE}`, ce qui garde les secrets dans un seul fichier en 600.

Pour retirer un serveur : `claude mcp remove --scope user <nom>`.

## Notes

Playwright a besoin d'un navigateur installé. Si le serveur est connecté mais
qu'un outil échoue, lancer `npx playwright install chromium`.

Un serveur MCP marqué connecté veut seulement dire que son processus a
démarré. Cela ne prouve pas que sa clé est valide ni que son API est
joignable.
