#!/bin/sh

if [ -n "$V4L_ARGS" ]; then
  v4l2-ctl --all --list-formats-ext
  echo Running: v4l2-ctl $V4L_ARGS --all
  v4l2-ctl $V4L_ARGS
fi

echo Running: ffmpeg -nostdin -loglevel error $FFMPEG_ARGS $WWW_DIR/$STREAM_DIR/stream.m3u8
#exec ffmpeg -nostdin -loglevel error $FFMPEG_ARGS $WWW_DIR/$STREAM_DIR/stream.m3u8
exec ffmpeg -nostdin -nostats $FFMPEG_ARGS $WWW_DIR/$STREAM_DIR/stream.m3u8
