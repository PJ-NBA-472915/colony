FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=colony
ARG USER_UID=1000
ARG USER_GID=1000

# Install ZeroTier, OpenSSH, and supervisor
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    openssh-server \
    supervisor \
    sudo \
    && curl -s https://install.zerotier.com | bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Rename existing ubuntu user to colony and set up sudo
RUN usermod -l $USER -d /home/$USER -m ubuntu \
    && groupmod -n $USER ubuntu \
    && echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USER

# Configure sshd
RUN mkdir -p /run/sshd \
    && sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#TCPKeepAlive.*/TCPKeepAlive yes/' /etc/ssh/sshd_config \
    && sed -i 's/#ClientAliveInterval.*/ClientAliveInterval 30/' /etc/ssh/sshd_config \
    && sed -i 's/#ClientAliveCountMax.*/ClientAliveCountMax 120/' /etc/ssh/sshd_config

# Prepare user SSH directory
RUN mkdir -p /home/$USER/.ssh \
    && chmod 700 /home/$USER/.ssh \
    && chown $USER:$USER /home/$USER/.ssh

# Supervisor config directory
RUN mkdir -p /etc/supervisor/conf.d

# Copy configs and entrypoint
COPY config/supervisor/ /etc/supervisor/conf.d/
COPY scripts/entrypoint.sh /app/scripts/entrypoint.sh
RUN chmod +x /app/scripts/entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
