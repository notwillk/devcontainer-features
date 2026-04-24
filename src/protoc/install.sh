#!/bin/bash
set -e

PROTOC_VERSION="${VERSION:-25.3}"

apt-get update && apt-get install -y curl unzip ca-certificates

curl -L -o /tmp/protoc.zip \
  "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip"

unzip /tmp/protoc.zip -d /usr/local

rm -f /tmp/protoc.zip

protoc --version
