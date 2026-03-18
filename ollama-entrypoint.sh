#!/bin/sh

ollama serve &

until ollama list > /dev/null 2>&1; do
  echo "Waiting for ollama to start..."
  sleep 1
done

echo "Pulling nomic-embed-text..."
ollama pull nomic-embed-text
echo "Model ready."

wait
