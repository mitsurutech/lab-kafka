# Lab Apache Kafka avec Docker Compose : topics, producteurs, consommateurs, partitions et offsets dans le navigateur

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-kafka/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-kafka/actions/workflows/check.yml)

Un **lab Apache Kafka** prêt à l’emploi pour la classe, issu de la [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning), où les écoles et les établissements donnent à chaque élève ses propres bases de données, conteneurs et terminal dans le navigateur. Chaque élève reçoit sa propre copie d’un **Apache Kafka à un seul broker** (mode KRaft, sans ZooKeeper) avec **Kafka UI** à côté, pour **créer un topic, produire des messages, les relire depuis le début** et observer les **partitions et les offsets** qui font Kafka, sans rien installer.

Tout tient dans un seul fichier `docker-compose`, `compose.yaml`, qui fonctionne de la même façon sur votre propre machine et sur la plateforme, où chaque élève obtient une copie privée sans aucun accès à internet.

## Ce que vous y trouvez

| Service | Image | Mémoire | Ce que c’est |
| --- | --- | --- | --- |
| `kafka` | [`apache/kafka:4.2.2`](https://hub.docker.com/r/apache/kafka) | 512 Mo (256 Mo de tas) | un nœud qui est à la fois broker et contrôleur, avec la création automatique de topics désactivée pour qu’un topic existe parce que vous l’avez créé |
| `kafka-ui` | [`kafbat/kafka-ui:v1.5.0`](https://github.com/kafbat/kafka-ui) | 512 Mo | une page web pour créer des topics, produire et lire des messages, et voir les partitions et les offsets |

Les deux images s’exécutent sous un utilisateur sans privilèges et sont figées sur une version, jamais `latest`. Le lab est volontairement petit : environ 590 Mo utilisés au repos, opérationnel en une dizaine de secondes une fois les images téléchargées. Il sert à apprendre, pas à encaisser une charge, et rien n’est conservé à l’arrêt du lab.

## L’utiliser sur la plateforme

La [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning) donne à chaque élève sa propre copie d’un lab, dans le navigateur, avec un terminal à côté.

**Pour l’essayer :** ouvrez la [page des conteneurs](https://mitsurutech.co.uk/fr/container), trouvez ce lab dans **Laboratoires d’exemple** et appuyez sur Démarrer. Aucun compte n’est nécessaire pour en essayer un.

**Pour le donner comme travail à une classe :**

1. Dans votre module, créez une tâche de type **Lab** et choisissez **Dans un dépôt GitHub**.
2. Indiquez `https://github.com/mitsurutech/lab-kafka` avec la branche `main`. Le fichier compose est celui par défaut, `compose.yaml`. Faites d’abord un fork du dépôt si vous voulez modifier le fichier.
3. Publiez. La copie de chaque élève part du commit que vous avez publié, de sorte qu’une modification ultérieure ici ne change pas un lab déjà donné.
4. Précisez dans la tâche ce qu’il faut rendre (voir [Pour les enseignants](#pour-les-enseignants)), puis distribuez-la comme n’importe quelle autre tâche.

Le manuel a une [page pour ce lab](https://mitsurutech.co.uk/fr/help/lab-kafka) et un [guide des labs de conteneurs](https://mitsurutech.co.uk/fr/help/labs) qui couvre le reste : ce qu’un fichier compose peut contenir, la mémoire dont dispose une copie, et comment un enseignant ouvre, suit et note la copie d’un élève.

Pas encore de compte d’établissement ? [La première année est gratuite](https://mitsurutech.co.uk/fr/pricing) jusqu’à 50 élèves, et [l’inscription](https://mitsurutech.co.uk/fr/signup) ne demande qu’une adresse e-mail.

## L’exécuter sur votre propre machine

Il vous faut Docker avec le plugin Compose. Le premier démarrage télécharge les images.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Ouvrez <http://localhost:8080> pour Kafka UI. `local.yaml` publie ce seul port sur `127.0.0.1` uniquement, de sorte qu’il n’est accessible que depuis votre ordinateur. Le broker n’est pas publié : sur votre propre machine, atteignez-le depuis un autre conteneur du même réseau sous le nom `kafka:9092`. Arrêtez-le avec `Ctrl-C` et supprimez-le avec `docker compose -f compose.yaml -f local.yaml down -v`.

## Pas à pas

1. **Ouvrez Kafka UI** et choisissez le cluster, `lab`. Il affiche un broker et aucun topic.
2. **Créez un topic.** Topics, puis Add a Topic : un nom tel que `orders` et **3 partitions**. Un topic est un journal nommé ; ses partitions sont les morceaux en lesquels il est découpé. Le facteur de réplication est de 1, puisqu’il n’y a qu’un broker.
3. **Produisez des messages.** Sur la page du topic, appuyez sur Produce Message, choisissez une partition et envoyez-en quelques-uns avec une clé et une valeur. Chaque message est ajouté à la fin d’une partition et reçoit le **offset** suivant dans celle-ci, en comptant à partir de zéro. Chaque partition compte de son côté.
4. **Relisez-les depuis le début.** L’onglet Messages du topic lit avec un sélecteur de position qui démarre sur Newest ; réglez-le pour lire depuis le début, ce que fait un nouveau consommateur lorsqu’il n’a aucune position enregistrée. Chaque ligne indique son offset et sa partition.
5. **Observez les offsets.** L’Overview du topic liste chaque partition avec son First Offset et son Next Offset. Le next offset est l’offset que recevra le prochain message : une partition qui contient deux messages a donc un next offset de 2.

Le terminal à côté du lab fait la même chose avec `curl`, car le poste de travail n’a pas les outils en ligne de commande de Kafka : Kafka UI a une API web, accessible depuis le terminal sous le nom `kafka-ui:8080`, et c’est elle qu’appelle la page elle-même. Par exemple, ceci crée un topic puis liste l’offset de chaque partition :

```bash
curl -s -X POST -H "Content-Type: application/json" -d '{"name":"orders","partitions":3,"replicationFactor":1,"configs":{}}' http://kafka-ui:8080/api/clusters/lab/topics -o /dev/null -w "%{http_code}"
curl -s http://kafka-ui:8080/api/clusters/lab/topics/orders | grep -o '"partition":[0-9]*\|"offsetMax":[0-9]*'
```

Produire par cette API demande un numéro de partition : une commande en désigne donc une.

## Pour les enseignants

Rien dans ce lab n’est noté automatiquement. L’élève rend des preuves et vous les notez, comme pour n’importe quel autre lab.

**Demandez des preuves en deux parties.** D’abord, la preuve du travail : une capture d’écran des partitions du topic avec leurs offsets, et des messages relus depuis le début. Ensuite, la compréhension : dans ses propres mots, pourquoi chaque partition commence à compter à zéro, pourquoi lire depuis le début renvoie des messages que le lecteur n’avait jamais vus, et ce qui changerait avec plus d’un broker.

**Sa place dans un cursus.** Kafka convient à une unité sur l’architecture événementielle, la messagerie et les files d’attente, les pipelines de big data ou les systèmes distribués : l’idée qu’un topic est un journal en ajout seul et que la position d’un consommateur n’est qu’un offset. Vérifiez l’unité de votre propre organisme de certification pour la formulation exacte ; aucune n’est citée ici.

**Qui voit quoi.** Une copie est privée pour l’élève qui l’a démarrée. Un membre du personnel qui enseigne le module peut l’ouvrir pour voir ce que l’élève a fait, et l’ouverture du travail d’un élève est inscrite dans le journal d’accès, que l’élève peut lire.

## Ce qui ne fonctionne pas dans un lab

Le lab n’a aucun accès à internet, rien d’extérieur ne peut donc lire ou écrire dans le broker. Il n’y a qu’un broker : la réplication, l’élection d’un leader et le rééquilibrage d’un groupe de consommateurs entre brokers sont décrits, pas montrés. Les messages et les topics du broker ne sont pas conservés à l’arrêt du lab. Le terminal n’a pas les outils en ligne de commande de Kafka comme `kafka-topics.sh` ; ils se trouvent dans l’image du broker, pas dans le terminal, c’est pourquoi le lab enseigne avec Kafka UI et son API web.

## Dépannage

- **Kafka UI n’apparaît pas tout de suite après Démarrer.** Attendez quelques secondes et appuyez de nouveau sur Ouvrir : le lab ne se déclare prêt que lorsque le broker répond et que la page a démarré.
- **Un topic que vous aviez créé a disparu.** Le broker ne garde rien d’une exécution à l’autre ; créez-le de nouveau.
- **Sur votre propre machine, le port 8080 est déjà utilisé.** Changez le nombre de gauche dans `local.yaml`, par exemple `127.0.0.1:8081:8080`, et ouvrez ce port à la place.

## Vérifier le lab

`test/check.sh` démarre le lab comme le fait l’exécuteur de la plateforme pour chaque service (toutes les capacités retirées, `no-new-privileges`, une limite de processus, des limites de mémoire et aucun accès à internet), puis vérifie depuis l’intérieur de son réseau ce que cette page promet : un broker KRaft, un topic de trois partitions, des messages envoyés vers deux d’entre elles avec chaque partition qui compte à partir de zéro, et une lecture depuis le début. Il demande Docker et s’exécute à chaque push, ce qui correspond au badge en haut de la page.

```bash
test/check.sh
```

## Versions et licences

[Apache Kafka](https://kafka.apache.org) est sous licence Apache-2.0 et [Kafka UI](https://github.com/kafbat/kafka-ui) est sous licence Apache-2.0. Les images sont `apache/kafka:4.2.2` et `kafbat/kafka-ui:v1.5.0`, exécutées sans modification à partir des images publiques des projets eux-mêmes ; rien d’elles n’est construit ni redistribué ici.

Les applications qu’elles contiennent ont les licences de leurs propres projets, indiquées ci-dessus.

## Licence

Cette œuvre est sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Vous pouvez la partager et l’adapter pour apprendre et enseigner, à condition de citer Mitsuru Technologies Ltd, de ne pas l’utiliser commercialement et de partager tout ce que vous en tirez sous la même licence. Le texte complet est dans le fichier `LICENSE`.

## À propos

Réalisé par [Mitsuru Technologies](https://mitsurutech.co.uk) pour la [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning) : Python, Java, Go, Node, SQL et Linux dans le navigateur pour les écoles et les établissements, avec des labs de conteneurs, des applications web déployées depuis GitHub et des quiz qui se corrigent seuls. Essayez du code sans compte dans le [bac à sable](https://mitsurutech.co.uk/fr/playground).

D’autres labs du même éditeur : [lab-valkey](https://github.com/mitsurutech/lab-valkey), [lab-spark](https://github.com/mitsurutech/lab-spark), [lab-observability](https://github.com/mitsurutech/lab-observability), [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin) et [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea).
