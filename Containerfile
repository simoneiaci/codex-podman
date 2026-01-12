FROM node:20-slim

# Install system dependencies and tools
RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    wget \
    gnupg \
    ca-certificates \
    jq \
    vim \
    less \
    unzip \
    zip \
    openssh-client \
    python3 \
    python3-pip \
    build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Git Credential Manager (only available on amd64)
RUN ARCH=$(dpkg --print-architecture) && \
        if [ "$ARCH" = "amd64" ]; then \
            curl -L "https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.4.1/gcm-linux_${ARCH}.2.4.1.deb" -o /tmp/gcm.deb && \
            dpkg -i /tmp/gcm.deb && \
            rm /tmp/gcm.deb; \
        else \
            echo "Skipping Git Credential Manager install for architecture: $ARCH"; \
        fi

# Install Codex CLI
RUN npm install -g @openai/codex

# Create non-root user without home directory (mount supplies /home/codex)
RUN useradd -d /home/codex -s /bin/bash -M codex && \
    mkdir -p /workspace && \
    chown codex:codex /workspace

USER codex
ENV HOME=/home/codex

WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]
