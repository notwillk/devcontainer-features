# Devcontainer Features

A set of individual [devcontainer features](https://containers.dev/implementors/features/) for various tools.

## Features

| Tool                | Feature                                                      | Options               |
|---------------------|--------------------------------------------------------------|-----------------------|
| alias               | ghcr.io/notwillk/devcontainer-features/alias                 | `name`, `exec`        |
| checksy             | ghcr.io/notwillk/devcontainer-features/checksy               | `version`             |
| claude-auth-persist | ghcr.io/notwillk/devcontainer-features/claude-auth-persist   | -                     |
| codex-auth-persist  | ghcr.io/notwillk/devcontainer-features/codex-auth-persist    | -                     |
| copilot-auth-persist| ghcr.io/notwillk/devcontainer-features/copilot-auth-persist  | -                     |
| devcontainer-cli    | ghcr.io/notwillk/devcontainer-features/devcontainer-cli      | `version`             |
| github-cli          | ghcr.io/notwillk/devcontainer-features/github-cli            | `version`             |
| golang              | ghcr.io/notwillk/devcontainer-features/golang                | `version`             |
| jq                  | ghcr.io/notwillk/devcontainer-features/jq                    | `version`             |
| just                | ghcr.io/notwillk/devcontainer-features/just                  | `version`             |
| node                | ghcr.io/notwillk/devcontainer-features/node                  | `version`             |
| openscad-cli        | ghcr.io/notwillk/devcontainer-features/openscad-cli          | -                     |
| pnpm                | ghcr.io/notwillk/devcontainer-features/pnpm                  | `version`             |
| skills              | ghcr.io/notwillk/devcontainer-features/skills                | `skills`              |
| sqlfs               | ghcr.io/notwillk/devcontainer-features/sqlfs                 | `version`             |
| turbo               | ghcr.io/notwillk/devcontainer-features/turbo                 | `version`             |
| uv                  | ghcr.io/notwillk/devcontainer-features/uv                    | `version`             |
| yq                  | ghcr.io/notwillk/devcontainer-features/yq                    | `version`             |

## Auth Persistence Features

`claude-auth-persist`, `codex-auth-persist`, and `copilot-auth-persist` each mount a Docker named volume at the tool's credential directory, so authentication survives devcontainer rebuilds without touching the host filesystem.

```jsonc
{
  "features": {
    "ghcr.io/notwillk/devcontainer-features/claude-auth-persist:1": {},
    "ghcr.io/notwillk/devcontainer-features/codex-auth-persist:1": {},
    "ghcr.io/notwillk/devcontainer-features/copilot-auth-persist:1": {}
  }
}
```

Each devcontainer gets its own isolated volume, named using the devcontainer ID. The volume persists across rebuilds and is never tied to the host filesystem.
