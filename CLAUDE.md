# Instructions de projet

## Lecture des documents : toujours passer par MarkItDown

Pour lire un PDF, un Word (`.docx`) ou un Excel (`.xlsx`, `.xls`), utilise
toujours l'outil `convert_to_markdown` du serveur MCP `markitdown`. Ne tente
pas de lire ces fichiers avec l'outil Read, avec `cat`, ni avec une
bibliothèque Python écrite pour l'occasion : le binaire est illisible tel quel
et une extraction improvisée perd la structure du document.

La règle vaut aussi pour les autres formats couverts par MarkItDown :
PowerPoint, CSV, JSON, XML, HTML, ZIP, EPUB, images et audio.

`convert_to_markdown` prend un seul paramètre, `uri`, qui doit porter un
schéma. Pour un fichier local, c'est `file://` suivi du chemin absolu, par
exemple `file:///home/user/plugin/rapport.pdf`. Un chemin nu comme
`rapport.pdf` est refusé. Les schémas `http:`, `https:` et `data:` sont
acceptés également, donc un PDF en ligne se convertit sans téléchargement
préalable.

Deux limites à connaître avant d'annoncer un résultat. Un PDF scanné, c'est-à-dire
une image de page sans couche de texte, ne rend presque rien : le dire plutôt
que de conclure que le document est vide. Et sur un Excel, la conversion rend
les valeurs des cellules, pas les formules ni la mise en forme ; si la question
porte sur une formule, le préciser.
