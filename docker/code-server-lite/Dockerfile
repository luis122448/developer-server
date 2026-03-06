# Usamos la imagen de LinuxServer.io que es superior para gestion de permisos
FROM lscr.io/linuxserver/code-server:latest

# Instalamos dependencias basicas (Zsh)
RUN apt-get update && apt-get install -y \
    zsh \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Instalamos nvm y Gemini CLI
# En las imagenes de LinuxServer, el usuario es 'abc' y su home suele ser /config
ENV NVM_DIR /config/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install --lts \
    && nvm use --lts \
    && npm install -g @google/gemini-cli

# Instalacion de Oh My Zsh (para el usuario root y abc)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Copiar configuraciones (En LinuxServer la ruta es /config/data/User/)
RUN mkdir -p /config/data/User
COPY settings.json /config/data/User/settings.json

# Configuracion de terminal (Cargar nvm en zsh)
RUN echo 'export NVM_DIR="/config/.nvm"' >> /root/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /root/.zshrc && \
    echo 'cd /home/coder/project' >> /root/.zshrc

# Nota: LinuxServer usa su propio sistema de inicio (s6-overlay), 
# por lo que no necesitamos definir un ENTRYPOINT personalizado.
