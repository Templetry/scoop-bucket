# Templetry scoop bucket

Install the [Templetry](https://github.com/Templetry) CLI and MCP server on Windows with [scoop](https://scoop.sh):

```powershell
scoop bucket add templetry https://github.com/Templetry/scoop-bucket
scoop install templetry
```

You get `templetry` and `templetry-mcp` on your PATH. Update with `scoop update templetry`.

## How the manifest stays current

Scoop's `autoupdate` block describes *how* to compute a new version; it does not
run itself — a bucket maintainer has to. Here that maintainer is
[`bin/update.sh`](bin/update.sh), on a daily schedule:

1. read the latest [engine release](https://github.com/Templetry/engine/releases),
2. take the hashes from its `SHA256SUMS` asset — never recompute them,
3. rewrite `bucket/templetry.json` and commit, only if the version moved.

[`bin/check.sh`](bin/check.sh) then guards the result on every push and weekly:
valid JSON, one hash per URL, every URL pointing at the manifest's own version,
and every URL actually resolving. That last check is the one that catches a
release asset withdrawn upstream — a failure no local test can see.

The engine's release workflow can also fire this immediately via
`repository_dispatch` (`engine-released`); without it the bucket lags a release
by at most a day.
