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

# Install nvm, Node.js LTS, and Gemini CLI
ENV NVM_DIR /home/coder/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install --lts \
    && nvm use --lts \
    && npm install -g @google/gemini-cli

# Add nvm and Node to the shell profile to be available in the terminal
RUN echo "\n# NVM & Node Configuration" >> /home/coder/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /home/coder/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> /home/coder/.bashrc
