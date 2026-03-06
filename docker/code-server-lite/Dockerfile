# Use the official code-server image as a base
FROM codercom/code-server:latest

# Switch to the root user to install basic system dependencies
USER root

# Install minimum dependencies for Node.js and git
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root coder user
USER coder

# Install nvm, Node.js LTS, and Gemini CLI in a single layer
ENV NVM_DIR /home/coder/.nvm
ENV NODE_VERSION lts/*
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && npm install -g @google/gemini-cli

# Inherit settings/themes (if files exist in the build context)
RUN mkdir -p /home/coder/.local/share/code-server/User && \
    mkdir -p /home/coder/.config/code-server/User

COPY --chown=coder:coder settings.json /home/coder/.config/code-server/User/settings.json

# Add nvm to the shell profile to be available in the terminal
RUN echo "\n# NVM Configuration" >> /home/coder/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /home/coder/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> /home/coder/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> /home/coder/.bashrc