#!/usr/bin/env bash
# What the README promises, checked from inside the lab's own network: run by check.sh. It
# types the commands the README and the lesson give, with the tools the platform's terminal has.
set -euo pipefail
: "${NET:?run through test/check.sh}"
probe() { docker run --rm --network "$NET" lab-kafka-check-probe bash -c "$1"; }
echo "- Kafka UI sees one broker, in KRaft mode, and no topics yet"
probe '
set -eu
out=$(curl -fs http://kafka-ui:8080/api/clusters)
echo "$out" | grep -q "\"brokerCount\":1" || { echo "no single broker: $out" >&2; exit 1; }
echo "$out" | grep -q "\"controller\":\"KRAFT\"" || { echo "not KRaft: $out" >&2; exit 1; }
echo "$out" | grep -q "\"topicCount\":0" || { echo "topics already there: $out" >&2; exit 1; }
'
echo "- a topic of three partitions is made, every partition empty"
probe '
set -eu
J="Content-Type: application/json"; B=http://kafka-ui:8080/api/clusters/lab/topics
code=$(curl -s -X POST -H "$J" -d "{\"name\":\"orders\",\"partitions\":3,\"replicationFactor\":1,\"configs\":{}}" $B -o /dev/null -w "%{http_code}")
[ "$code" = 200 ] || { echo "make topic answered $code" >&2; exit 1; }
got=$(curl -fs $B/orders | grep -o "\"partition\":[0-9]*\|\"offsetMax\":[0-9]*" | paste -sd" ")
[ "$got" = "\"partition\":0 \"offsetMax\":0 \"partition\":1 \"offsetMax\":0 \"partition\":2 \"offsetMax\":0" ] || { echo "partitions: $got" >&2; exit 1; }
echo "- three messages go to two partitions and each partition counts from zero"
send() { curl -s -X POST -H "$J" -d "{\"partition\":$1,\"key\":\"$2\",\"value\":\"$3\",\"headers\":{},\"keySerde\":\"String\",\"valueSerde\":\"String\"}" $B/orders/messages -o /dev/null -w "%{http_code}"; }
for c in "0 alice coffee" "0 alice tea" "1 bob cake"; do
  [ "$(send $c)" = 200 ] || { echo "produce $c refused" >&2; exit 1; }
done
got=$(curl -fs $B/orders | grep -o "\"partition\":[0-9]*\|\"offsetMax\":[0-9]*" | paste -sd" ")
[ "$got" = "\"partition\":0 \"offsetMax\":2 \"partition\":1 \"offsetMax\":1 \"partition\":2 \"offsetMax\":0" ] || { echo "offsets: $got" >&2; exit 1; }
echo "- reading from the beginning returns all three with their offsets"
got=$(curl -fsN "$B/orders/messages/v2?seekType=BEGINNING&limit=10" | grep -o "\"partition\":[0-9]*,\"offset\":[0-9]*\|\"value\":\"[a-z]*\"" | paste -sd" " )
for want in "\"partition\":0,\"offset\":0 \"value\":\"coffee\"" "\"partition\":0,\"offset\":1 \"value\":\"tea\"" "\"partition\":1,\"offset\":0 \"value\":\"cake\""; do
  case "$got" in *"$want"*) ;; *) echo "missing $want in: $got" >&2; exit 1;; esac
done
'
echo "  ok"
