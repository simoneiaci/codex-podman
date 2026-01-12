# codex-podman

Run the Codex CLI in a minimal Podman container on Apple Silicon (arm64). This repo includes a `Containerfile` and a clean, repeatable workflow for build, auth, and daily use.

## Features

- Codex CLI
- GitHub CLI (`gh`)
- Git (Git Credential Manager only on amd64 builds)
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
  "${CODEX_POD_HOME:-$HOME/.codex-home}" \
  "$HOME/.openai" \
  "$HOME/.config/openai"
```
# Create container (if missing)
alias codex-pod-init='podman ps -a --format {{.Names}} | grep -q "^codex$" || (mkdir -p "${CODEX_POD_HOME}" && podman create --name codex --user "$(id -u):$(id -g)" --interactive --tty --security-opt no-new-privileges --cap-drop=ALL --memory="4g" --cpus="2.0" --pids-limit 100 --pull=never -e HOME=/home/codex -v "${CODEX_POD_HOME}:/home/codex" -v "$HOME/.gitconfig:/home/codex/.gitconfig:ro" -v "$HOME/.ssh:/home/codex/.ssh:ro" -v "${AI_WORKSPACE_DIR}:/workspace" -w /workspace localhost/codex:arm64)'

# Start / attach to existing container
alias codex-pod='podman start -ai codex'
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
RUN ARCH=$(dpkg --print-architecture) && \
  curl -L "https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.4.1/gcm-linux_${ARCH}.2.4.1.deb" -o /tmp/gcm.deb && \
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

> **Apple Silicon (M1–M4) note:** These instructions target arm64 hosts like your MacBook Pro. Git Credential Manager is skipped on this architecture, so rely on SSH credentials mounted from the host for git operations.

```sh
podman build --platform=linux/arm64 -t localhost/codex:arm64 .
```

> **Note:** Podman will automatically pull the base image if not present locally.
## Configure workspace path

# Create container (if missing)

```bash
export AI_WORKSPACE_DIR="$HOME/workspace"
```

## Configure container home (per account)

Choose a dedicated directory for the container's Codex data so your personal credentials stay separate from any corporate login already configured on the host:

```bash
export CODEX_POD_HOME="$HOME/.codex-home-personal"
mkdir -p "$CODEX_POD_HOME"
```

> **Tip:** Point `CODEX_POD_HOME` somewhere other than the directory your corporate CLI session uses (commonly `~/.codex-home`) so the container mounts only your personal account data.

## Create container (one time)

```sh
mkdir -p "$CODEX_POD_HOME"

podman create \
  --name codex \
  --user "$(id -u):$(id -g)" \
  --interactive \
  --tty \
  --security-opt no-new-privileges \
  --cap-drop=ALL \
  --memory="4g" \
  --cpus="2.0" \
  --pids-limit 100 \
  --pull=never \
  -e HOME=/home/codex \
  -v "${CODEX_POD_HOME}:/home/codex" \
  -v "$HOME/.gitconfig:/home/codex/.gitconfig:ro" \
  -v "$HOME/.ssh:/home/codex/.ssh:ro" \
  -v "${AI_WORKSPACE_DIR}:/workspace" \
  -w /workspace \
  localhost/codex:arm64
```

> **Note:** Your host `~/.gitconfig` and `~/.ssh` are mounted read-only, so git commands use your existing git identity and SSH keys. Run this creation step once; future sessions reuse the same container.

> **Tip:** If you created the container before adding the interactive TTY flags or the `CODEX_POD_HOME` mount, remove it (`podman rm -f codex`) and recreate it so `podman start -ai codex` drops you into a personal-only shell.

## Authenticate (first start)

```sh
podman start -ai codex
```

Inside the shell, run:

```bash
codex login --device-auth
```

- Uses device auth
- No localhost callback
- Token saved to `${CODEX_POD_HOME}` on the host via `/home/codex` inside the container

Exit the shell to stop the container.

## Daily usage

```sh
podman start -ai codex
```

## Verify

```bash
codex whoami
```
## Shell aliases

For quick access, add these to your `.zshrc` or `.bashrc`:

> **Reminder:** Export `CODEX_POD_HOME` in your shell startup file before using the aliases so they mount the correct personal directory.

```bash
# Create container (if missing)
alias codex-pod-init='podman ps -a --format {{.Names}} | grep -q "^codex$" || (mkdir -p "${CODEX_POD_HOME}" && podman create --name codex --user "$(id -u):$(id -g)" --interactive --tty --security-opt no-new-privileges --cap-drop=ALL --memory="4g" --cpus="2.0" --pids-limit 100 --pull=never -e HOME=/home/codex -v "${CODEX_POD_HOME}:/home/codex" -v "$HOME/.gitconfig:/home/codex/.gitconfig:ro" -v "$HOME/.ssh:/home/codex/.ssh:ro" -v "${AI_WORKSPACE_DIR}:/workspace" -w /workspace localhost/codex:arm64)'

# Start / attach to existing container
alias codex-pod='podman start -ai codex'
```

Then use simply:

```bash
codex-pod
```
