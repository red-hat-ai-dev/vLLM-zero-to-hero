#!/bin/sh
set -eu

url="http://localhost:8000"
attempt=0

printf "Waiting for vLLM"
until curl --fail --silent "$url/v1/models" >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 120 ]; then
    echo
    echo "vLLM did not become ready within 10 minutes." >&2
    exit 1
  fi
  printf "."
  sleep 5
done
echo

curl --fail --silent --show-error "$url/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5-2b",
    "messages": [
      {"role": "user", "content": "Explain containers in three sentences."}
    ]
  }'
echo

