FROM debian:latest

ARG TZ
ENV TZ="$TZ"

ARG UID=1000
ARG GID=1000
ARG USER_NAME="timo"

ARG CLAUDE_CODE_VERSION="latest"

# Install basic development tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
  aggregate \
  bat \
  build-essential \
  dnsutils \
  eza \
  fish \
  fzf \
  gh \
  git \
  gnupg2 \
  hx \
  iproute2 \
  ipset \
  iptables \
  jq \
  less \
  man-db \
  nodejs \
  npm \
  pkg-config \
  procps \
  rustup \
  starship \
  sudo \
  unzip
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Add a non-root user.
RUN groupadd -g $GID -o $USER_NAME
RUN useradd -m -u $UID -g $GID -G sudo -o -s /bin/fish $USER_NAME

# Allow user to sudo without a password.
RUN sed -i 's/%sudo	ALL=(ALL:ALL) ALL/%sudo ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Ensure default node user has access to /usr/local/share.
RUN mkdir -p /usr/local/share/npm-global && chown -R $USER_NAME:$USER_NAME /usr/local/share

# Create workspace and config directories and set permissions.
RUN mkdir -p /workspace /home/$USER_NAME/.claude && chown -R $USER_NAME:$USER_NAME /workspace /home/$USER_NAME/.claude

# Install global packages.
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set user and workspace.
USER $USER_NAME
WORKDIR /home/$USER_NAME/workspace

# Install rust for the user.
RUN rustup toolchain install stable

# Set the default shell to fish.
ENV SHELL=/bin/fish

# Set the default editor and visual.
ENV EDITOR=hx
ENV VISUAL=hx

# Install Claude.
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

ENTRYPOINT ["claude"]
