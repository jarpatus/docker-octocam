# docker-octocam
Lightweight webcam streamer and web server to be used e.g. with OctoPrint. Uses ffmpeg to copy/transcode webcam audio and video and to create HLS stream which is then made available over HTTP so that it can be used with all modern browser without any external plugins (external javascript is needed for non-Safari though). Optionally srtream can be started and stopped externally i.e. from OctoPrint. 

# Build
Clone repository to src/, create docker-compose.yaml and build:

```
git clone https://github.com/jarpatus/docker-octocam.git src
nano docker-compose.yaml
docker-compose build
```

# Compose file
```
services:
  octocam:
    container_name: octocam
    build:
      context: src
    restart: 'no'
    environment:
      - UID=5024
      - GID=5024
      - STREAM_DIR=/stream
      - STREAM_URL=https://octoprint/stream
      - AUTOSTART=true
      - V4L_ARGS=--device=/dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=H264
      - FFMPEG_ARGS=-f v4l2 -input_format h264 -video_size 1920x1080 -framerate 30 -i /dev/video0
                    -f alsa -i hw:1,0,0
                    -c:v copy
                    -c:a aac
                    -f hls -hls_time 2 -hls_list_size 5 -hls_allow_cache 0
                    -hls_flags delete_segments
#      - V4L_ARGS=--device=/dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=mjpeg
#      - FFMPEG_ARGS=-f v4l2 -input_format mjpeg -video_size 1920x1080 -framerate 30 -i /dev/video0
#                    -f alsa -i hw:1,0,0
#                    -c:v libx264 -profile:v baseline -level 3.0 -pix_fmt yuv420p -tune zerolatency -preset veryfast
#                    -g 60 -sc_threshold 0
#                    -c:a aac
#                    -f hls -hls_time 2 -hls_list_size 5 -hls_allow_cache 0
#                    -hls_flags delete_segments
    devices:
      - /dev/snd:/dev/snd
      - /dev/video0:/dev/video0
    tmpfs:
      - /www:size=64m
    volumes:
      - ./run:/run/supervisor
    ports:
      - 8080:8080
```

### Environment 
Mandatory environment variables:
* ```STREAM_URL``` - URL to HSL stream files on included HTTP server i.e. http://octoprint/stream 
* ```V4L_ARGS``` - Arguments for v4l2-ctl for setting up webcam for streaming.
* ```FFMPEG_ARGS``` - Arguments for ffmpeg for creating HLS stream.

Optional environment variables:
* ```UID``` - UID to run container with. Defaults to 5024.
* ```GID``` - GID to run container with. Defaults to 5024.
* ```STREAM_DIR``` - Directory to which HLS stream files are placed on included HTTP server. Defautls to /stream.
* ```AUTOSTART``` - If set to false then stream won't be started on container start and must be started externally. Defaults to true.

### Devices
Audio and video device files must be made available for the container, typically /dev/snd and /dev/video0 or /dev/video1.

### Tmpfs
You absolutely do want to mount tmpfs as /www as in example so that HLS stream files are kept in memory only and won't be written to disk.

### Volumes
If you want to start and stop stream externally then you may want to mount some folder on your host to /run/supervisor as unix socket allowing to control ffmpeg and httpd will be created there. Running the stream only when needed may be good idea to save some resources especially if transcoding has to be used.


