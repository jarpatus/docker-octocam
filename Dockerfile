# Start from Apline linux
FROM alpine:3.18

# Build args
ARG UID=1000
ARG GID=1000

# Expose ports
EXPOSE 8080

# Set some defaults
ENV WWW_DIR=/www

# Add packages
RUN apk add --no-cache busybox-extras ffmpeg supervisor v4l-utils

# Add user 
RUN addgroup -g $GID octocam
RUN adduser -s /sbin/nologin -G octocam -D -H -u $UID octocam
RUN addgroup octocam audio
RUN addgroup octocam video

# Create config files
RUN mkdir -p /run/supervisor
RUN chown octocam:octocam /run/supervisor
RUN mkdir -p $WWW_DIR/$STREAM_DIR
RUN chown octocam:octocam $WWW_DIR/$STREAM_DIR
COPY ./app/etc /etc
COPY ./app/www $WWW_DIR/$STREAM_DIR

# Drop root
USER octocam

# Start supervisor
CMD supervisord
