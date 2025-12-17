FROM alpine:3.19

# Install nginx + openssh
RUN apk add --no-cache nginx openssh bash

# Create nginx dirs
RUN mkdir -p /run/nginx

# Generate SSH host keys
RUN ssh-keygen -A

# Create kids group and users
RUN addgroup kids && \
    adduser -D -G kids graham && \
    adduser -D -G kids caroline

# Copy configs
COPY nginx.conf /etc/nginx/nginx.conf
COPY sshd_config /etc/ssh/sshd_config
COPY start.sh /start.sh
RUN chmod +x /start.sh

# HTTP for nginx, 2222 for SFTP
EXPOSE 80 2222

CMD ["/start.sh"]
