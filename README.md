# codex-podman

Run the Codex CLI in a minimal Podman container on Apple Silicon (arm64). This repo includes a `Containerfile` and a clean, repeatable workflow for build, auth, and daily use.

## Prerequisites

- Podman installed and working
- Node-based image pulled by Podman (`node:20-slim`)

## Clean environment

Remove the container, image, and any leftover containers from the image, plus local Codex config:

```sh
# Remove container (by name)
podman rm -f codex 2>/dev/null

# Remove image
podman rmi -f codex:arm64 2>/dev/null

# Remove any leftover containers from the image
podman rm -f $(podman ps -aq --filter ancestor=codex) 2>/dev/null

# Remove Codex auth/config on host
rm -rf \
  "$HOME/.codex-home" \
  "$HOME/.openai" \
  "$HOME/.config/openai"
```

## Build image

The `Containerfile`:

```Dockerfile
FROM node:20-slim

RUN npm install -g @openai/codex

ENV HOME=/home/codex
RUN mkdir -p /home/codex && chmod 777 /home/codex

WORKDIR /workspace
ENTRYPOINT ["codex"]
```

Build:

```sh
cd ~/codex-podman
podman build --platform=linux/arm64 -t codex:arm64 .
```

## Authenticate (one time)

```sh
mkdir -p "$HOME/.codex-home"

podman run --rm -it \
  --name codex \
  --user "$(id -u):$(id -g)" \
  -e HOME=/home/codex \
  -v "$HOME/.codex-home:/home/codex" \
  -v "$HOME/Documents/AI:/workspace" \
  -w /workspace \
  codex:arm64 login --device-auth
```

- Uses device auth
- No localhost callback
- Token saved to `~/.codex-home`

## Daily usage

```sh
podman run --rm -it \
  --name codex \
  --user "$(id -u):$(id -g)" \
  -e HOME=/home/codex \
  -v "$HOME/.codex-home:/home/codex" \
  -v "$HOME/Documents/AI:/workspace" \
  -w /workspace \
  codex:arm64
```

## Verify

```sh
codex whoami
```
