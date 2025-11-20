V="${VERSION:-latest}"

ARCH="$(dpkg --print-architecture)"

case
  "$ARCH" in amd64|arm64) GOARCH="$ARCH"
  *) echo "Unsupported arch: $ARCH" >&2; exit 1
esac

curl -fsSL "https://go.dev/dl/go${V}.linux-${GOARCH}.tar.gz" -o /tmp/go.tar.gz

rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
ln -sf /usr/local/go/bin/go /usr/local/bin/go

rm /tmp/go.tar.gz
go version
