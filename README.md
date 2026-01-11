# codex-podman

Run the Codex CLI in a minimal Podman container on Apple Silicon (arm64). This repo includes a `Containerfile` and a clean, repeatable workflow for build, auth, and daily use.

## Features

- Codex CLI
- GitHub CLI (`gh`)
- Git with Git Credential Manager
- Node.js & npm (pre-installed)
- Python 3 & pip
- Development tools: curl, wget, jq, vim, zip/unzip, build-essential
- SSH client
- Persistent authentication

## Requirements

- Podman
- A working OpenAI Codex account

## Clean environment

Remove the container, image, and any leftover containers from the image, plus local Codex config:

```sh
# Remove container (by name)
podman rm -f codex 2>/dev/null

# Remove image
podman rmi -f localhost/codex:arm64 2>/dev/null

# Remove any leftover containers from the image
podman rm -f $(podman ps -aq --filter ancestor=localhost/codex:arm64) 2>/dev/null

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

# Install system dependencies and tools
RUN apt-get update && \
    apt-get install -y \
    git curl wget gnupg ca-certificates \
    jq vim less unzip zip openssh-client \
    python3 python3-pip build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Git Credential Manager
RUN curl -L https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.4.1/gcm-linux_amd64.2.4.1.deb -o /tmp/gcm.deb && \
    dpkg -i /tmp/gcm.deb && rm /tmp/gcm.deb

RUN npm install -g @openai/codex

RUN useradd -d /home/codex -s /bin/bash -M codex && \
  mkdir -p /workspace && \
  chown codex:codex /workspace

USER codex
ENV HOME=/home/codex

WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]
```

Build:

```sh
podman build --platform=linux/arm64 -t localhost/codex:arm64 .
```

> **Note:** Podman will automatically pull the base image if not present locally.

## Configure workspace path

Set your workspace directory (customize this to your needs):

```bash
export AI_WORKSPACE_DIR="$HOME/workspace"
```

## Authenticate (one time)

```sh
mkdir -p "$HOME/.codex-home"

podman run --rm -it \
  --name codex \
  --user "$(id -u):$(id -g)" \
  -e HOME=/home/codex \
  -v "$HOME/.codex-home:/home/codex" \
  -v "$HOME/.gitconfig:/home/codex/.gitconfig:ro" \
  -v "$HOME/.ssh:/home/codex/.ssh:ro" \
  -v "${AI_WORKSPACE_DIR}:/workspace" \
  -w /workspace \
  localhost/codex:arm64 -c "codex login --device-auth"
```

- Uses device auth
- No localhost callback
- Token saved to `~/.codex-home`

> **Note:** Your host `~/.gitconfig` and `~/.ssh` are mounted read-only, so git commands will use your existing git identity and SSH keys for GitHub authentication.

## Daily usage

```sh
podman run --rm -it \
  --name codex \
  --user "$(id -u):$(id -g)" \
  --security-opt no-new-privileges \
  --cap-drop=ALL \
  --memory="4g" \
  --cpus="2.0" \
  --pids-limit 100 \
  -e HOME=/home/codex \
  -v "$HOME/.codex-home:/home/codex" \
  -v "$HOME/.gitconfig:/home/codex/.gitconfig:ro" \
  -v "$HOME/.ssh:/home/codex/.ssh:ro" \
  -v "${AI_WORKSPACE_DIR}:/workspace" \
  -w /workspace \
  localhost/codex:arm64
```

**Security features:**
- `--security-opt no-new-privileges`: Prevents privilege escalation
- `--cap-drop=ALL`: Drops all Linux capabilities
- `--memory="4g"`: Limits memory usage to 4GB
- `--cpus="2.0"`: Limits CPU usage to 2 cores
- `--pids-limit 100`: Prevents fork bombs by limiting processes

## Verify

```bash
codex whoami
```

## Shell aliases

For quick access, add these to your `.zshrc` or `.bashrc`:

```bash
# First-time authentication
alias codex-pod-init='mkdir -p "$HOME/.codex-home" && podman run --rm -it --name codex --user "$(id -u):$(id -g)" -e HOME=/home/codex -v "$HOME/.codex-home:/home/codex" -v "$HOME/.gitconfig:/home/codex/.gitconfig:ro" -v "$HOME/.ssh:/home/codex/.ssh:ro" -v "${AI_WORKSPACE_DIR}:/workspace" -w /workspace localhost/codex:arm64 -c "codex login --device-auth"'

# Daily usage
alias codex-pod='podman run --rm -it --name codex --user "$(id -u):$(id -g)" --security-opt no-new-privileges --cap-drop=ALL --memory="4g" --cpus="2.0" --pids-limit 100 -e HOME=/home/codex -v "$HOME/.codex-home:/home/codex" -v "$HOME/.gitconfig:/home/codex/.gitconfig:ro" -v "$HOME/.ssh:/home/codex/.ssh:ro" -v "${AI_WORKSPACE_DIR}:/workspace" -w /workspace localhost/codex:arm64'
```

Then use simply:
```bash
codex-pod
```
