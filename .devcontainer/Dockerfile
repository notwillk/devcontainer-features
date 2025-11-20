FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN sudo apt-get install -y curl \
  && curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash - \
  && sudo apt-get install -y nodejs \
  && node -v

RUN npm install -g @devcontainers/cli@"$V"
