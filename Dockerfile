FROM ubuntu:22.04

RUN apt update && apt install -y \
    openssh-server \
    curl \
    wget \
    unzip \
    sudo \
    python3 \
    iptables \
    && mkdir /var/run/sshd

RUN useradd -m sun && echo "sun:123456@" | chpasswd && adduser sun sudo

RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config && \
    echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config

RUN curl -fsSL https://tailscale.com/install.sh | sh

COPY start-tailscale-ssh.sh /usr/local/bin/start-tailscale-ssh.sh
RUN chmod +x /usr/local/bin/start-tailscale-ssh.sh

EXPOSE 8080 22 14489 888 80 443 20 21

CMD ["/usr/local/bin/start-tailscale-ssh.sh"]
