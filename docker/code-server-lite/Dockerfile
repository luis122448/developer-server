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

# Establecer Zsh como shell por defecto
RUN chsh -s /usr/bin/zsh coder

# Switch back to the non-root coder user
USER coder

# Install nvm, Node.js LTS, and Gemini CLI
ENV NVM_DIR /home/coder/.nvm
ENV NODE_VERSION lts/*
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && npm install -g @google/gemini-cli

# --- INSTALACION DE OH MY ZSH ---
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Inherit settings/themes
RUN mkdir -p /home/coder/.local/share/code-server/User && \
    mkdir -p /home/coder/.config/code-server/User
COPY --chown=coder:coder settings.json /home/coder/.local/share/code-server/User/settings.json
COPY --chown=coder:coder settings.json /home/coder/.config/code-server/User/settings.json

# --- CONFIGURACION DE SHELL ---
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> /home/coder/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/coder/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /home/coder/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/coder/.zshrc && \
    echo 'cd /home/coder/project' >> /home/coder/.zshrc

# Establecer el directorio de trabajo y asegurar permisos
USER root
RUN mkdir -p /home/coder/project && chown -R coder:coder /home/coder/project
USER coder
WORKDIR /home/coder/project

# Comando para iniciar code-server
ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "/home/coder/project"]
