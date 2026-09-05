# Architecture

## Local-first model

This feed installs a local observer and a LuCI view on each router. It is not a
fleet controller and it does not expose a remote shell. A central system such
as Multica may collect the fixed JSON status output, but it must not use this
package as an arbitrary-command transport.

```text
LuCI view
  │ fixed ubus methods only
  ▼
rpcd ucode ──► agent-runtime CLI ──► status / signature verification
  │                    │
  │                    └── optional local runtime directories
  ▼
bounded async-job record in /tmp
```

The frontend can invoke only `check`, `verify`, and `reconcile`. The core CLI
does not accept a caller-provided command, URL, archive, package, service, or
filesystem path.

## Provider boundary

`agent-runtime` recognizes an optional runtime at configured roots, but does
not ship it. A future provider package may implement a signed archive contract
and generation activation. It must:

1. use a fixed trusted release origin and public key;
2. verify every index, manifest and archive before extraction;
3. stage outside the active generation and atomically switch only after health
   checks;
4. retain a rollback target and bounded operation logs;
5. add fixed, separately ACL-protected RPC methods rather than widening the
   existing API.

This is how the richer Hotwa firmware integration can be moved here without
making a generic LuCI package responsible for site-specific Node, uv, Pi,
Multica or browser credentials.
