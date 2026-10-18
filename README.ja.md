# Docker Compose で動かす Apache Kafka ラボ：トピック、プロデューサー、コンシューマー、パーティション、オフセットをブラウザーで

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-kafka/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-kafka/actions/workflows/check.yml)

授業でそのまま使える **Apache Kafka ラボ**です。学校や学校法人が、生徒一人ひとりにデータベース、コンテナー、ブラウザー上のターミナルを用意できる [MitsuruTech ラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)から提供しています。生徒はそれぞれ、**ブローカー 1 台の Apache Kafka**（KRaft モード、ZooKeeper なし）と、その横の **Kafka UI** を専用に使えます。**トピックを作り、メッセージを送り、最初から読み戻し**、Kafka を Kafka たらしめている**パーティションとオフセット**を観察できます。何もインストールする必要はありません。

ファイルは `docker-compose` ファイル 1 つ、`compose.yaml` だけです。自分のマシンでもプラットフォームでも同じように動きます。プラットフォームでは、生徒ごとに専用のコピーが用意され、インターネットへの出口はありません。

## 中身

| サービス | イメージ | メモリ | 役割 |
| --- | --- | --- | --- |
| `kafka` | [`apache/kafka:4.2.2`](https://hub.docker.com/r/apache/kafka) | 512 MB（ヒープ 256 MB） | ブローカーとコントローラーを兼ねる 1 つのノードです。トピックの自動作成は無効なので、トピックは自分で作ったから存在します |
| `kafka-ui` | [`kafbat/kafka-ui:v1.5.0`](https://github.com/kafbat/kafka-ui) | 512 MB | トピックの作成、メッセージの送信と読み取り、パーティションとオフセットの確認ができる Web ページです |

どちらのイメージも権限のないユーザーで動き、バージョンを固定しています（`latest` は使いません）。意図的に小さくしてあり、待機中の使用量は約 590 MB で、イメージのダウンロード後は約 10 秒で正常に動き始めます。学習のためのもので、負荷をかけるためのものではありません。ラボを止めると何も保存されません。

## プラットフォームで使う

[MitsuruTech ラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)では、生徒一人ひとりがブラウザー上で、ターミナルを横に置いたラボの専用コピーを使えます。

**試すには：**[コンテナーのページ](https://mitsurutech.co.uk/ja/container)を開き、**サンプルラボ**からこのラボを選んで「起動」を押します。試すだけならアカウントは不要です。

**クラスの課題として出すには：**

1. モジュールで、種類が**ラボ**の課題を作り、**GitHub リポジトリ**を選びます。
2. `https://github.com/mitsurutech/lab-kafka` とブランチ `main` を指定します。compose ファイルは既定の `compose.yaml` です。ファイルを変更したい場合は、先にリポジトリをフォークしてください。
3. 公開します。生徒のコピーはどれも、公開した時点のコミットから始まるので、あとでここを変更しても、すでに出したラボは変わりません。
4. 何を提出するかを課題に書き（[教員の方へ](#教員の方へ)を参照）、ほかの課題と同じように配布します。

マニュアルには、このラボの[ページ](https://mitsurutech.co.uk/ja/help/lab-kafka)と、そのほかのことを説明する[コンテナーラボのガイド](https://mitsurutech.co.uk/ja/help/labs)があります。compose ファイルに書けること、コピーが使えるメモリの量、教員が生徒のコピーを開いて見て採点する方法などです。

学校のアカウントはまだありませんか？[最初の 1 年は無料](https://mitsurutech.co.uk/ja/pricing)で、生徒 50 人まで使えます。[登録](https://mitsurutech.co.uk/ja/signup)にはメールアドレスだけが必要です。

## 自分のマシンで動かす

Compose プラグイン付きの Docker が必要です。初回の起動では、イメージをダウンロードします。

```bash
docker compose -f compose.yaml -f local.yaml up
```

Kafka UI は <http://localhost:8080> で開きます。`local.yaml` が公開するのはこのポート 1 つだけで、しかも `127.0.0.1` に限られるので、自分のコンピューターからしかアクセスできません。ブローカーは公開されていません。自分のマシンでは、同じネットワーク上の別のコンテナーから `kafka:9092` として接続します。`Ctrl-C` で止め、`docker compose -f compose.yaml -f local.yaml down -v` で削除します。

## 進め方

1. **Kafka UI を開き**、クラスター `lab` を選びます。ブローカーが 1 台、トピックは 0 件と表示されます。
2. **トピックを作ります。**Topics、続いて Add a Topic を選び、`orders` などの名前と **3 パーティション**を指定します。トピックは名前の付いたログで、パーティションはそれを分けたものです。ブローカーが 1 台なので、レプリケーションファクターは 1 です。
3. **メッセージを送ります。**トピックのページで Produce Message を押し、パーティションを選んで、キーと値を付けたメッセージをいくつか送ります。メッセージはそれぞれ 1 つのパーティションの末尾に追加され、そのパーティションの次の**オフセット**が付きます。オフセットは 0 から数えます。パーティションごとに別々に数えます。
4. **最初から読み戻します。**トピックの Messages タブは、読み始める位置を選ぶコントロールで読み取ります。初期値は Newest なので、先頭から読むように変えてください。保存された位置を持たない新しいコンシューマーがすることと同じです。各行にオフセットとパーティションが表示されます。
5. **オフセットを確認します。**トピックの Overview には、各パーティションの First Offset と Next Offset が一覧されます。Next Offset は次のメッセージに付くオフセットなので、メッセージが 2 件あるパーティションの Next Offset は 2 です。

ラボの横にあるターミナルでも、`curl` で同じことができます。ワークベンチには Kafka のコマンドラインツールがないからです。Kafka UI には Web API があり、ターミナルからは `kafka-ui:8080` で届きます。ページ自身もこれを呼び出しています。たとえば次のコマンドは、トピックを作ってから各パーティションのオフセットを一覧します。

```bash
curl -s -X POST -H "Content-Type: application/json" -d '{"name":"orders","partitions":3,"replicationFactor":1,"configs":{}}' http://kafka-ui:8080/api/clusters/lab/topics -o /dev/null -w "%{http_code}"
curl -s http://kafka-ui:8080/api/clusters/lab/topics/orders | grep -o '"partition":[0-9]*\|"offsetMax":[0-9]*'
```

この API でメッセージを送るにはパーティション番号が必要なので、コマンドでは 1 つを指定します。

## 教員の方へ

このラボには自動採点がありません。生徒が証拠を提出し、教員が、ほかのラボと同じように採点します。

**証拠は 2 つに分けて求めてください。**1 つ目は作業の証拠です。トピックのパーティションとそのオフセットのスクリーンショット、そして最初から読み戻したメッセージのスクリーンショットです。2 つ目は理解です。自分の言葉で、なぜどのパーティションも 0 から数え始めるのか、なぜ最初から読むと読み手がまだ見ていないメッセージが返ってくるのか、ブローカーが複数になると何が変わるのか、を書いてもらいます。

**コースでの位置づけ。**Kafka は、イベント駆動アーキテクチャ、メッセージングとキュー、ビッグデータのパイプライン、分散システムの単元に向いています。トピックは追記のみのログで、コンシューマーの位置はオフセットにすぎない、という考え方を学べます。正確な表現は、ご自身の認定団体の単元でご確認ください。ここでは引用していません。

**誰が何を見られるか。**コピーは、起動した生徒だけのものです。そのモジュールを教えている教職員は、生徒の作業内容を確認するためにコピーを開けます。生徒の作業を開いたことはアクセスログに記録され、生徒はそれを読めます。

## ラボでできないこと

ラボにはインターネットへの出口がまったくないので、外部からブローカーを読み書きすることはできません。ブローカーは 1 台なので、レプリケーション、リーダー選出、ブローカー間でのコンシューマーグループのリバランスは、説明はできても実際には見せられません。ブローカーのメッセージとトピックは、ラボを止めると保存されません。ターミナルには `kafka-topics.sh` などの Kafka のコマンドラインツールがありません。それらはブローカーのイメージにあり、ターミナルにはないため、このラボでは Kafka UI とその Web API を使って学びます。

## トラブルシューティング

- **「起動」の直後に Kafka UI が表示されません。**数秒待ってから、もう一度「開く」を押してください。ラボは、ブローカーが応答し、ページが起動してから、初めて準備完了と表示します。
- **作ったトピックが消えました。**ブローカーは実行のあいだ何も保持しません。もう一度作ってください。
- **自分のマシンで、ポート 8080 がすでに使われています。**`local.yaml` の左側の数字を変え（たとえば `127.0.0.1:8081:8080`）、代わりにそのポートを開いてください。

## ラボの検証

`test/check.sh` は、プラットフォームのランナーがすべてのサービスを起動するのと同じ条件（すべてのケーパビリティを削除、`no-new-privileges`、プロセス数の制限、メモリの制限、インターネットへの出口なし）でラボを起動し、そのネットワークの内側から、このページの内容を確認します。KRaft のブローカーが 1 台あること、3 パーティションのトピックがあること、そのうち 2 つにメッセージが入り、どのパーティションも 0 から数えること、最初から読み戻せること、です。Docker が必要で、push のたびに実行されます。ページ上部のバッジがそれです。

```bash
test/check.sh
```

## バージョンとライセンス

[Apache Kafka](https://kafka.apache.org) は Apache-2.0 でライセンスされ、[Kafka UI](https://github.com/kafbat/kafka-ui) も Apache-2.0 でライセンスされています。イメージは `apache/kafka:4.2.2` と `kafbat/kafka-ui:v1.5.0` で、各プロジェクト自身の公開イメージを変更せずに実行しており、ここではそれらのビルドも再配布も行っていません。

中のアプリケーションは、上にリンクした、それぞれのプロジェクトのライセンスに従います。

## ライセンス

この作品は [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) でライセンスされています。Mitsuru Technologies Ltd のクレジットを表示し、商用に使わず、これをもとに作ったものを同じライセンスで共有するなら、学習と授業のために共有・改変できます。全文は `LICENSE` ファイルにあります。

## この演習について

[Mitsuru Technologies](https://mitsurutech.co.uk) が、[MitsuruTech ラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)のために作りました。学校向けに、Python、Java、Go、Node、SQL、Linux をブラウザーで使えるようにし、コンテナーラボ、GitHub から公開する Web アプリ、自動採点されるクイズも備えています。アカウントなしでコードを試せる[プレイグラウンド](https://mitsurutech.co.uk/ja/playground)もあります。

同じ提供元のほかのラボ：[lab-valkey](https://github.com/mitsurutech/lab-valkey)、[lab-spark](https://github.com/mitsurutech/lab-spark)、[lab-observability](https://github.com/mitsurutech/lab-observability)、[lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics)、[lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin)、[lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea)。
