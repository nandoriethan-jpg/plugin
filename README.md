# Faire de ta machine l'appareil principal pour Claude Code

Playwright, Firecrawl et Perplexity, disponibles dans toutes les sessions
Claude Code et tous les projets de ta machine. Les clés ne sont jamais
committées.

## Pourquoi en local plutôt que dans le cloud

Les serveurs MCP ne servent à rien s'ils ne joignent pas leurs API. Dans un
conteneur Claude Code cloud, la politique réseau refuse `api.firecrawl.dev` et
`api.perplexity.ai`, et Playwright n'a pas de navigateur à piloter chez toi.
Sur ta machine, aucune de ces limites ne s'applique.

Un serveur marqué connecté veut seulement dire que son processus a démarré.
Cela ne prouve ni que sa clé est valide, ni que son API est joignable.

## Parcours machine neuve

1. Installer Node.js 18 ou plus récent, requis parce que les trois serveurs
   sont lancés par `npx`.
2. Installer Claude Code :

   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```

3. Cloner ce dépôt, renseigner les clés, lancer le script :

   ```bash
   git clone https://github.com/nandoriethan-jpg/plugin
   cd plugin
   cp .env.example .env    # puis remplir les 2 clés
   ./scripts/setup-mcp-global.sh
   ```

4. Installer le navigateur de Playwright :

   ```bash
   npx playwright install chromium
   ```

5. Redémarrer Claude Code. Les serveurs sont lus au démarrage d'une session.

Le script vérifie d'abord `python3`, `node` et `claude`, et nomme la commande
d'installation manquante le cas échéant. Il refuse de tourner si une clé
manque, sans rien écrire. Il fusionne dans tes fichiers existants au lieu de
les écraser, pose `settings.json` en permissions 600, et finit par un
`claude mcp list` de contrôle. L'option `--no-verify` saute ce contrôle.

## La méthode, en deux fichiers

| Fichier | Rôle |
| --- | --- |
| `~/.claude.json` | déclare les trois serveurs en scope utilisateur, clés référencées par `${VARIABLE}` |
| `~/.claude/settings.json` | donne les valeurs de ces variables dans son bloc `env` |

Claude Code lit lui-même ces deux fichiers au démarrage de chaque session,
quel que soit le dossier courant. C'est le scope utilisateur qui donne le
« partout » : un `.mcp.json` de projet ne vaut que dans ce projet, et des
variables exportées à la main ne valent que pour ce shell.

Poser les clés dans `settings.json` plutôt que dans un `.zshrc` a un avantage
concret. Claude Code les lit directement, donc la configuration vaut aussi pour
l'application desktop, qui ne lit pas forcément un profil de shell.

## Le .mcp.json du dépôt

Ce dépôt déclare aussi les trois serveurs dans `.mcp.json`, avec la même
syntaxe `${VARIABLE}`. C'est redondant avec l'installation globale sur ta
machine, mais utile ailleurs : une session cloud, une autre machine, ou un
collaborateur qui clone le dépôt. Les deux coexistent sans conflit, la config
de projet ayant la priorité.

## Si tu veux aussi des sessions cloud

Il faut définir les clés comme secrets de l'environnement et autoriser les
hôtes ci-dessous dans sa politique réseau, sinon les serveurs démarrent mais
leurs appels échouent.

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
