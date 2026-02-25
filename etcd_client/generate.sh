#!/usr/bin/env bash
set -euo pipefail

ETCD_COMMIT="4e814e204934c3c682d9e185db1dfb646d2510b3"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PROTO_DIR="$SCRIPT_DIR/proto"
RESULT_DIR="$SCRIPT_DIR/result"

# Step 1: Checkout etcd proto files at the pinned commit
echo "==> Fetching etcd proto files at commit ${ETCD_COMMIT}..."
rm -rf "$PROTO_DIR"
mkdir -p "$PROTO_DIR/etcd"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/etcd-io/etcd.git "$tmpdir/etcd"
cd "$tmpdir/etcd"
git sparse-checkout set api server/etcdserver/api/v3lock/v3lockpb
git fetch --depth 1 origin "$ETCD_COMMIT"
git checkout "$ETCD_COMMIT"
cd "$SCRIPT_DIR"

cp -r "$tmpdir/etcd/api" "$PROTO_DIR/etcd/api"
mkdir -p "$PROTO_DIR/etcd/server/etcdserver/api/v3lock"
cp -r "$tmpdir/etcd/server/etcdserver/api/v3lock/v3lockpb" "$PROTO_DIR/etcd/server/etcdserver/api/v3lock/v3lockpb"

# Step 2: Apply patch to strip Go-specific annotations (gogoproto, grpc-gateway, openapi)
echo "==> Applying patch..."
cd "$PROTO_DIR/etcd"
patch -p1 --no-backup-if-mismatch < "$SCRIPT_DIR/drop-dependencies.patch"
cd "$SCRIPT_DIR"

# Step 3: Generate Ruby gRPC code in Docker
echo "==> Generating Ruby gRPC stubs in Docker (Ruby 3.4)..."
rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR"

docker run --rm \
  --platform linux/amd64 \
  -v "$SCRIPT_DIR:/work" \
  -w /work \
  ruby:3.4 bash -c '
    bundle install --quiet &&
    bundle exec grpc_tools_ruby_protoc \
      -I ./proto \
      --ruby_out=./result \
      --grpc_out=./result \
      proto/etcd/api/etcdserverpb/rpc.proto \
      proto/etcd/api/authpb/auth.proto \
      proto/etcd/api/mvccpb/kv.proto \
      proto/etcd/api/versionpb/version.proto \
      proto/etcd/server/etcdserver/api/v3lock/v3lockpb/v3lock.proto
  '

echo "==> Done. Generated files:"
find "$RESULT_DIR" -type f | sort

# Step 4: Copy generated files to lib/etcdv3/rpc
DEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/lib/etcdv3/rpc"
echo "==> Copying generated files to ${DEST_DIR}..."
rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"
cp -r "$RESULT_DIR"/* "$DEST_DIR"/

echo "==> Installed to protobuf4 folder:"
find "$DEST_DIR" -type f | sort
