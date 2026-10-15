# Apache Kafka lab with Docker Compose: topics, producers, consumers, partitions and offsets in the browser

[![check](https://github.com/mitsurutech/lab-kafka/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-kafka/actions/workflows/check.yml)

A ready-made **Apache Kafka lab** for classrooms, from the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), where schools and colleges give every student their own databases, containers and terminal in the browser. Each student gets their own copy of a **single-broker Apache Kafka** (KRaft mode, no ZooKeeper) with **Kafka UI** beside it, to **create a topic, produce messages, read them back from the beginning** and watch the **partitions and offsets** that make Kafka what it is, with nothing installed.

It is one `docker-compose` file, `compose.yaml`, and it runs the same on your own machine as it does on the platform, where every student gets a private copy with no way out to the internet.

## What is in it

| Service | Image | Memory | What it is |
| --- | --- | --- | --- |
| `kafka` | [`apache/kafka:4.2.2`](https://hub.docker.com/r/apache/kafka) | 512 MB (256 MB heap) | one node that is both broker and controller, auto-creation of topics off so a topic exists because you made it |
| `kafka-ui` | [`kafbat/kafka-ui:v1.5.0`](https://github.com/kafbat/kafka-ui) | 512 MB | a web page to make topics, produce and read messages, and see partitions and offsets |

Both images run as an unprivileged user and are pinned to a version, never `latest`. It is small on purpose: about 590 MB in use when idle, healthy in about ten seconds once the images are downloaded. It is for learning, not for load, and nothing is saved when the lab stops.

## Using it on the platform

The [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning) gives every student their own copy of a lab, in the browser, with a terminal beside it.

**To try it:** open the [container page](https://mitsurutech.co.uk/container), find this lab in **Sample labs** and press Start. No account is needed to try one.

**To set it as work for a class:**

1. In your module, make a task of type **Lab** and choose **In a GitHub repository**.
2. Give `https://github.com/mitsurutech/lab-kafka` with the branch `main`. The compose file is the default, `compose.yaml`. Fork the repository first if you want to change the file.
3. Publish. Every student's copy starts from the commit you published, so a later change here does not alter a lab already set.
4. Say in the task what to hand in (see [For teachers](#for-teachers)), and assign it like any other task.

The help manual has a [page for this lab](https://mitsurutech.co.uk/help/lab-kafka) and a [guide to container labs](https://mitsurutech.co.uk/help/labs) that covers the rest: what a compose file may say, how much memory a copy gets, and how a teacher opens, watches and marks a student's copy.

No college account yet? [Your first year is free](https://mitsurutech.co.uk/pricing) for up to 50 students, and [signing up](https://mitsurutech.co.uk/signup) takes an email address.

## Running it on your own machine

You need Docker with the Compose plugin. The first start downloads the images.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Open <http://localhost:8080> for Kafka UI. `local.yaml` publishes that one port on `127.0.0.1` only, so it is reachable from your own computer and from nowhere else. The broker is not published: on your own machine reach it from another container on the same network as `kafka:9092`. Stop it with `Ctrl-C`, and remove it with `docker compose -f compose.yaml -f local.yaml down -v`.

## Working through it

1. **Open Kafka UI** and choose the cluster, `lab`. It shows one broker and no topics.
2. **Make a topic.** Topics, then Add a Topic: a name such as `orders` and **3 partitions**. A topic is a named log; its partitions are the pieces it is split into. The replication factor is 1, because there is one broker.
3. **Produce messages.** On the topic's page press Produce Message, choose a partition, and send a few with a key and a value. Each message is appended to the end of one partition and given the next **offset** in it, counting from zero. Every partition counts on its own.
4. **Read them back from the beginning.** The topic's Messages tab reads with a seek control that starts on Newest; set it to read from the beginning, which is what a new consumer does when it has no saved position. Each row shows its offset and partition.
5. **See the offsets.** The topic's Overview lists each partition with its First Offset and Next Offset. The next offset is the offset the next message will get, so a partition holding two messages has a next offset of 2.

The terminal beside the lab does the same things with `curl`, because the workbench has no Kafka command-line tools: Kafka UI has a web API, reachable from the terminal as `kafka-ui:8080`, and it is what the page itself calls. For example, this makes a topic and then lists each partition's offset:

```bash
curl -s -X POST -H "Content-Type: application/json" -d '{"name":"orders","partitions":3,"replicationFactor":1,"configs":{}}' http://kafka-ui:8080/api/clusters/lab/topics -o /dev/null -w "%{http_code}"
curl -s http://kafka-ui:8080/api/clusters/lab/topics/orders | grep -o '"partition":[0-9]*\|"offsetMax":[0-9]*'
```

Producing through that API needs a partition number, so a command names one.

## For teachers

Nothing in this lab is marked automatically. The student hands in evidence and you mark it, the way you mark any other lab.

**Ask for evidence in two halves.** First, proof of the work: a screenshot of the topic's partitions with their offsets, and of the messages read back from the beginning. Second, the understanding: in their own words, why every partition starts counting at zero, why reading from the beginning returns messages the reader never saw before, and what would change with more than one broker.

**Where it sits in a course.** Kafka suits a unit on event-driven architecture, messaging and queues, big-data pipelines or distributed systems: the idea that a topic is an append-only log and a consumer's position is just an offset. Check your own awarding body's unit for the exact wording; none is quoted here.

**Who sees what.** A copy is private to the student who started it. A member of staff who teaches the module can open it to see what the student has done, and opening a student's work is written to the access log, which the student can read.

## What does not work in a lab

The lab has no way out to the internet at all, so nothing outside it can read or write the broker. It is one broker, so replication, leader election and a consumer group rebalancing across brokers are described, not shown. The broker's messages and topics are not saved when the lab stops. The terminal has no Kafka command-line tools such as `kafka-topics.sh`; those are in the broker's image, not in the terminal, so the lab teaches with Kafka UI and its web API instead.

## Troubleshooting

- **Kafka UI does not appear straight after Start.** Wait a few seconds and press Open again: the lab reports itself ready only once the broker answers and the page has started.
- **A topic you made is gone.** The broker keeps nothing between runs; make it again.
- **On your own machine, port 8080 is already in use.** Change the left-hand number in `local.yaml`, for example `127.0.0.1:8081:8080`, and open that port instead.

## Checking the lab

`test/check.sh` starts the lab the way the platform's runner starts every service (all capabilities dropped, `no-new-privileges`, a process limit, memory limits, and no way out to the internet) and then checks from inside its network what this page promises: one KRaft broker, a topic of three partitions, messages going to two of them with each partition counting from zero, and a read from the beginning. It needs Docker and runs on every push, which is the badge at the top.

```bash
test/check.sh
```

## Versions and licences

[Apache Kafka](https://kafka.apache.org) is Apache-2.0 licensed and [Kafka UI](https://github.com/kafbat/kafka-ui) is Apache-2.0 licensed. The images are `apache/kafka:4.2.2` and `kafbat/kafka-ui:v1.5.0`, run unmodified from the projects' own public images; nothing from them is built or redistributed here.

The compose file, the tests and this documentation are MIT licensed, see [LICENSE](LICENSE): copy it, change it, teach with it. The applications inside are the licences of their own projects, linked above.

## About

Made by [Mitsuru Technologies](https://mitsurutech.co.uk) for the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning): Python, Java, Go, Node, SQL and Linux in the browser for schools and colleges, with container labs, web apps deployed from GitHub, and quizzes that mark themselves. Try code with no account in the [playground](https://mitsurutech.co.uk/playground).

More labs from the same place: [lab-valkey](https://github.com/mitsurutech/lab-valkey), [lab-spark](https://github.com/mitsurutech/lab-spark), [lab-observability](https://github.com/mitsurutech/lab-observability), [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin) and [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea).
