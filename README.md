# Configuration des serveurs MCP

Ce dépôt déclare trois serveurs MCP dans `.mcp.json` : Playwright, Firecrawl
et Perplexity. Les clés ne sont pas dans le fichier. Elles sont lues depuis
l'environnement via la syntaxe `${VARIABLE}`, donc aucun secret n'est
committé. Playwright n'a besoin d'aucune clé.

## Pourquoi un fichier dans le dépôt

`claude mcp add --scope user` écrit dans `~/.claude.json`, qui est propre à une
machine. Dans une session Claude Code cloud, ce fichier disparaît avec le
conteneur. Un `.mcp.json` versionné est relu à chaque démarrage de session,
sur n'importe quelle machine.

## Mise en route locale

1. Copier `.env.example` en `.env` et remplir les deux valeurs.
2. Exporter les variables dans le shell avant de lancer Claude Code :

   ```bash
   set -a && . ./.env && set +a
   claude
   ```

3. Claude Code demande d'approuver les serveurs MCP du projet au premier
   démarrage. Répondre oui.
4. Vérifier avec `/mcp` dans la session, ou `claude mcp list` depuis le
   terminal.

## Mise en route en session cloud

Les variables doivent être définies comme secrets de l'environnement, et la
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

Pour une installation par machine plutôt que par dépôt. Noter que `-e` attend
une paire `NOM=valeur` : passer la clé seule est refusé.

```bash
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
claude mcp add --scope user firecrawl -e FIRECRAWL_API_KEY=... -- npx -y firecrawl-mcp
claude mcp add --scope user perplexity -e PERPLEXITY_API_KEY=... -- npx -y @perplexity-ai/mcp-server
```

## Notes

Playwright a besoin d'un navigateur installé. Si le serveur est connecté mais
qu'un outil échoue, lancer `npx playwright install chromium`.

Pour retirer un serveur ajouté par commande :
`claude mcp remove --scope user <nom>`.

## Redémarrer pour activer

Les serveurs MCP sont lus au démarrage d'une session. Quitter avec `/exit`
puis relancer `claude`. En session cloud, démarrer une nouvelle session.
