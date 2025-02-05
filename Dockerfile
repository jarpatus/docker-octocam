 # Start from Apline linux
FROM alpine:3.18

# Expose ports
EXPOSE 8080

# Set defaults
ENV UID=5024
ENV GID=5024
ENV WWW_DIR=/www
ENV STREAM_DIR=/stream
ENV AUTOSTART=true

# Add packages
RUN apk add --no-cache busybox-extras ffmpeg supervisor v4l-utils

# Add user 
RUN addgroup -g $GID user
RUN adduser -G user -D -H -u $UID user
RUN addgroup user audio
RUN addgroup user video

# Create config files
RUN mkdir -p /run/supervisor
RUN chown user:user /run/supervisor
RUN mkdir -p $WWW_DIR/$STREAM_DIR
RUN chown user:user $WWW_DIR/$STREAM_DIR
COPY ./app/etc /etc
COPY ./app/www $WWW_DIR/$STREAM_DIR

# Drop root
USER user

# Start supervisor
CMD supervisord
