FROM node:20-slim

# Install Codex CLI
RUN npm install -g @openai/codex

# Create a writable home directory (important for device auth)
ENV HOME=/home/codex
RUN mkdir -p /home/codex && chmod 777 /home/codex

WORKDIR /workspace
ENTRYPOINT ["codex"]
