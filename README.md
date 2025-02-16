# Octocam rootless
Lightweight rootless webcam streamer and web server to be used e.g. with OctoPrint. Uses ffmpeg to copy/transcode webcam audio and video and to create HLS stream which is then made available over HTTP so that it can be used with all modern browser without any external plugins (external javascript is needed for non-Safari though). Optionally srtream can be started and stopped externally i.e. from OctoPrint. 

# Compose file

## Example
```
services:
  octocam:
    container_name: octocam
    build:
      context: src
      args:
        - UID=5000
        - GID=5000
    restart: 'no'
    environment:
      - STREAM_DIR=/stream
      - AUTOSTART=true
      - FFMPEG_ARGS=-f v4l2 -input_format h264 -video_size 1920x1080 -framerate 30 -i /dev/video0
                    -f alsa -i hw:1,0,0
                    -c:v copy
                    -c:a aac
                    -f hls -hls_time 2 -hls_list_size 5 -hls_allow_cache 0
                    -hls_flags delete_segments
      - V4L_ARGS=--device=/dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=H264
#      - FFMPEG_ARGS=-f v4l2 -input_format mjpeg -video_size 1920x1080 -framerate 30 -i /dev/video0
#                    -f alsa -i hw:1,0,0
#                    -c:v libx264 -profile:v baseline -level 3.0 -pix_fmt yuv420p -tune zerolatency -preset veryfast
#                    -g 60 -sc_threshold 0
#                    -c:a aac
#                    -f hls -hls_time 2 -hls_list_size 5 -hls_allow_cache 0
#                    -hls_flags delete_segments
#      - V4L_ARGS=--device=/dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=mjpeg
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

## Build args
* ```UID``` - UID to run container with.
* ```GID``` - GID to run container with.

## Environment 
Mandatory environment variables:
* ```STREAM_DIR``` - Directory to which HLS stream files are placed on included HTTP server.
* ```AUTOSTART``` - If set to true then stream will be started on container start. If false then stream must be started externally.
* ```FFMPEG_ARGS``` - Arguments for ffmpeg for creating HLS stream.

Optional environment variables:
* ```V4L_ARGS``` - Arguments for v4l2-ctl for setting up webcam for streaming.

### Video4Linux
If V4L_ARGS environment variable is set then v4l2-ctl will be ran when stream is started to set up webcam for streaming. In example Logitech C930 (and older C920 models) could be set up to provide H.264 1080p stream which can be use as it without transcoding:
```
      - V4L_ARGS=--device=/dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=H264
```

Or mjpeg stream which would then require transcoding to H.264:
```
      - V4L_ARGS=--device=/dev/video0 --set-fmt-video=width=1920,height=1080,pixelformat=mjpeg
```

Exact commands depends on your webcam and it's capabilities. Getting usable H.264 stream directly from camera greatly reduced resource consumption as transcoding is not needed but may introduce huge lag (like 10+ seconds with C930) and quality can be relatively poor.

### ffmpeg

If webcam provides H.264 stream then we don't need transcoding and could use something like this:

```
      - FFMPEG_ARGS=-f v4l2 -input_format h264 -video_size 1920x1080 -framerate 30 -i /dev/video0
                    -f alsa -i hw:1,0,0
                    -c:v copy
                    -c:a aac
                    -f hls -hls_time 2 -hls_list_size 5 -hls_allow_cache 0
                    -hls_flags delete_segments
```

If not or if quality or latency is an issue then we can do transcoding: 

```
      - FFMPEG_ARGS=-f v4l2 -input_format mjpeg -video_size 1920x1080 -framerate 30 -i /dev/video0
                    -f alsa -i hw:1,0,0
                    -c:v libx264 -profile:v baseline -level 3.0 -pix_fmt yuv420p -tune zerolatency -preset veryfast
                    -g 60 -sc_threshold 0
                    -c:a aac
                    -f hls -hls_time 2 -hls_list_size 5 -hls_allow_cache 0
                    -hls_flags delete_segments
```

Exact ffmpeg arguments can be fine tuned but these seemed to work with older C920 and Chrome and Firefox. 

## Devices
Audio and video device files must be made available for the container, typically /dev/snd and /dev/video0 or /dev/video1. Container drops root privileges but adds user to audio and video groups so make sure your device files can be accessed by those groups.

## Tmpfs
You absolutely do want to mount tmpfs as /www as in example so that HLS stream files are kept in memory only and won't be written to disk.

## Volumes
If you want to start and stop stream externally then you may want to mount some folder on your host to /run/supervisor as unix socket allowing to control ffmpeg and httpd will be created there. Running the stream only when needed may be good idea to save some resources especially if transcoding has to be used (it is also possible to start and stop container from OctoPrint but I don't like giving full access to docker to any container).

# Accessing the stream
Video stram can be accessed from port 8080 under STREAM_DIR i.e. http://octocam.example:8080/stream . Index file will just show stream in HTML5 canvas (using hls.js if needed). Actual stream can be accessed from file stream.m3u8 e.g. http://octocam.example:8080/stream/stream.m3u8 (shuold just work with octoprint).

## Reverse proxying
If you are using octoprint container and i.e. traefik it could be nice idea to reverse proxy stream under octoprint. Also enforcing https is always good.

Example traefik config:

```
http:

  routers:
    octoprint-tls:
      entryPoints:
        - websecure
      rule: "Host(`octoprint`)"
      service: octoprint
      tls: {}
    octocam-tls:
      entryPoints:
        - websecure
      rule: "Host(`octoprint`) && PathPrefix(`/stream`)"
      service: octocam
      tls: {}

  services:
    octoprint:
      loadBalancer:
        servers:
          - url: "http://octoprint"
    octocam:
      loadBalancer:
        servers:
          - url: "http://octocam:8080"
```

# External control
Stream can be started and stopped externally by using supervisorctl as internally we use supervisor to manage ffmpeg and httpd. Mount some directory from host to /run/supervisor and you will supervisor.sock in it. Mount that directory to another container if needed e.g. OctoPrint and control from that container is possible.

In example in OctoPrint we could install System Command Editor (or just edit config files manually) and define commands like this:

Start stream: ```supervisorctl -s unix:///run/supervisor/supervisord.sock start all```

Stop stream: ```supervisorctl -s unix:///run/supervisor/supervisord.sock stop all```

If octoprint runs in container then it does not come with supervisorctrl so it must be installed using something like this: 
```
docker exec octoprint apt-get update
docker exec octoprint apt install -y supervisor
```

But it will disappear if container is re-created so could just create system command like this:

Install supervisor: ```apt-get update && apt install -y supervisor```
