🔵 PROCEDURE 1 — CODEX (Clean → Setup → Use)

1️⃣ Clean Codex environment ONLY

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


⸻

2️⃣ Build Codex image

Containerfile (~/codex-podman/Containerfile)

FROM node:20-slim

RUN npm install -g @openai/codex

ENV HOME=/home/codex
RUN mkdir -p /home/codex && chmod 777 /home/codex

WORKDIR /workspace
ENTRYPOINT ["codex"]

Build:

cd ~/codex-podman
podman build --platform=linux/arm64 -t codex:arm64 .


⸻

3️⃣ Authenticate Codex (ONE TIME)

mkdir -p "$HOME/.codex-home"

podman run --rm -it \
  --name codex \
  --user "$(id -u):$(id -g)" \
  -e HOME=/home/codex \
  -v "$HOME/.codex-home:/home/codex" \
  -v "$HOME/Documents/AI:/workspace" \
  -w /workspace \
  codex:arm64 login --device-auth

✔ Uses device auth
✔ No localhost callback
✔ Token saved to ~/.codex-home

⸻

4️⃣ Daily Codex usage (CLI only)

podman run --rm -it \
  --name codex \
  --user "$(id -u):$(id -g)" \
  -e HOME=/home/codex \
  -v "$HOME/.codex-home:/home/codex" \
  -v "$HOME/Documents/AI:/workspace" \
  -w /workspace \
  codex:arm64


⸻

5️⃣ Verify

codex whoami
