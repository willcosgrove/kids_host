FROM ruby:4.0-rc-alpine

# Install openssh and bash (Ruby is already in the base image)
RUN apk add --no-cache openssh bash build-base

# Generate SSH host keys
RUN ssh-keygen -A

# Create kids group (users created at runtime from KIDS env var)
RUN addgroup kids

# Set up Ruby app
WORKDIR /app
COPY Gemfile ./
RUN bundle install

# Copy application code
COPY config.ru server.rb ./

# Copy SSH config and startup script
COPY sshd_config /etc/ssh/sshd_config
COPY start.sh /start.sh
RUN chmod +x /start.sh

# HTTP for Puma, 2222 for SFTP
EXPOSE 80 2222

CMD ["/start.sh"]
