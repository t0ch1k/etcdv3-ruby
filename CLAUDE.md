# etcdv3-ruby

Ruby client library for etcd v3 API, using gRPC.

## Dev Environment

- Uses devenv (Nix) — `devenv shell` to enter
- Ruby 3.4, etcd 3.5 provided by Nix packages
- Main branch: `master`

## Commands

- `bundle exec rspec` — run all tests (spawns a local etcd instance automatically)
- `bundle exec rspec spec/path/to_spec.rb` — run a single spec file
- `ETCD_TEST_PORT=2389 bundle exec rspec` — use a different port if 2379 is taken

## Architecture

- `lib/etcdv3.rb` — main client class, public API
- `lib/etcdv3/connection_wrapper.rb` — connection management, reconnect logic
- `lib/etcdv3/connection.rb` — single connection to an etcd endpoint
- `lib/etcdv3/etcdrpc/` — protobuf-generated gRPC stubs (do not edit manually)
- `lib/etcdv3/namespace/` — namespace-prefixed variants of KV/watch/lock
- `spec/helpers/test_instance.rb` — manages local etcd process for tests

## Testing Notes

- Tests require etcd binary in PATH (provided by devenv)
- Test suite starts/stops etcd automatically via `spec_helper.rb`
- Default test port: 2379 (override with `ETCD_TEST_PORT` env var)
