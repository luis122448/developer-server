# Use the official linuxserver webtop image as a base
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Set frontend to noninteractive to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV DEEPSEEK_USE_LOCAL=false
ARG PASSWORD

# Switch to root user to install packages
USER root

# 1. Install prerequisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    apt-transport-https \
    gpg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Add Brave Browser repository
RUN curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-release.list

# 3. Add VSCodium repository
RUN curl https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor > /usr/share/keyrings/vscodium-archive-keyring.gpg && \
    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' > /etc/apt/sources.list.d/vscodium.list

# 4. Update package lists
RUN apt-get update

# 5. Install Brave Browser
RUN apt-get install -y --no-install-recommends brave-browser

# 6. Install VSCodium
RUN apt-get install -y --no-install-recommends codium

# 7. Install LibreOffice
RUN apt-get install -y --no-install-recommends libreoffice

# 8. Install NodeJS and gemini-cli
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g @google/gemini-cli run-deepseek-cli

# 9. Clean up apt cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 10. Configure user 'abc' with a password and sudo access
RUN apt-get update && \
    apt-get install -y sudo && \
    adduser abc sudo && \
    echo "abc:${PASSWORD}" | chpasswd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 11. Copy custom wallpaper to a temporary location
COPY background.png /tmp/background.png

# 12. Create default desktop shortcuts in a temporary location
RUN mkdir -p /tmp/desktop_icons && \
    echo '[Desktop Entry]\nVersion=1.0\nType=Application\nName=Brave Browser\nExec=/usr/bin/brave-browser-stable --no-sandbox\nIcon=brave-browser\nTerminal=false' > /tmp/desktop_icons/brave.desktop && \
    echo '[Desktop Entry]\nVersion=1.0\nType=Application\nName=VSCodium\nExec=/usr/bin/codium\nIcon=vscodium\nTerminal=false' > /tmp/desktop_icons/codium.desktop && \
    echo '[Desktop Entry]\nVersion=1.0\nType=Application\nName=Terminal\nExec=xfce4-terminal\nIcon=utilities-terminal\nTerminal=false' > /tmp/desktop_icons/terminal.desktop && \
    chmod +x /tmp/desktop_icons/*.desktop

# 13. Copy desktop initialization script
# This script handles setting the default wallpaper and desktop icons on first run.
COPY init-desktop.sh /etc/cont-init.d/50-desktop-init
RUN chmod +x /etc/cont-init.d/50-desktop-init