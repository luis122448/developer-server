# Use the official code-server image as a base
FROM codercom/code-server:latest

# Switch to the root user to install system dependencies
USER root

# Install minimum dependencies (Zsh, curl, git)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Set Zsh as the default shell for the coder user
RUN chsh -s /usr/bin/zsh coder

# Switch back to the non-root coder user
USER coder

# Install nvm and Node.js LTS
ENV NVM_DIR /home/coder/.nvm
ENV NODE_VERSION lts/*
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION

# Install Gemini CLI
RUN . $NVM_DIR/nvm.sh && npm install -g @google/gemini-cli

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Configure shell environment
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> /home/coder/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/coder/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /home/coder/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/coder/.zshrc

# Set the working directory
WORKDIR /home/coder/project

# Start code-server directly into the project folder
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "/home/coder/project"]
