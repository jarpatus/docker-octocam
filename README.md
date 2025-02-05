# docker-octocam
Lightweight webcam streamer and web server to be used e.g. with OctoPrint. Uses ffmpeg to copy/transcode webcam audio and video and to create HLS stream which is then made available over HTTP so that it can be used with all modern browser without any external plugins (external javascript is needed for non-Safari though). Sounds trivial but for some reason seemed to be extraordinary hard or at least rare thing...

# Build
Clone repository to src/, create docker-compose.yaml and build:

```
git clone https://github.com/jarpatus/docker-octocam.git src
nano docker-compose.yaml
docker-compose build
```

## Environment variables
Mandatory environment variables:
* ```STREAM_URL``` - URL to HSL stream files on included HTTP server i.e. http://octoprint/stream 
* ```V4L_ARGS``` - Arguments for v4l2-ctl for setting up webcam for streaming.
* ```FFMPEG_ARGS``` - Arguments for ffmpeg for creating HLS stream.

Optional environment variables:
* ```UID``` - UID to run container with. Defaults to 5024.
* ```GID``` - GID to run container with. Defaults to 5024.
* ```STREAM_DIR``` - Directory to which HLS stream files are placed on included HTTP server. Defautls to /stream.
* ```AUTOSTART``` - If set to false then stream won't be started on container start and must be started externally. Defaults to true.
