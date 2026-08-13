# Templetry scoop bucket

Install the [Templetry](https://github.com/Templetry) CLI and MCP server on Windows with [scoop](https://scoop.sh):

```powershell
scoop bucket add templetry https://github.com/Templetry/scoop-bucket
scoop install templetry
```

You get `templetry` and `templetry-mcp` on your PATH. Update with `scoop update templetry` — the manifest auto-tracks the [engine releases](https://github.com/Templetry/engine/releases).
