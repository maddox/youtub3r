# youtub3r!

Youtub3r scans your [Channels DVR Server](https://getchannels.com/dvr-serer/) and attempts to find the corresponding `info.json` files created by [Pinchflat](https://github.com/kieraneglin/pinchflat) and applies the metadata and artwork to the videos in Channels.

It will only attempt this for videos in your library that are part of Video Groups with the label "youtube" or genre "YouTube" applied.

## Organization

[Channels](https://getchannels.com) expects videos to be grouped into folders. These are calld [Video Groups](https://getchannels.com/docs/channels-dvr-server/how-to/local-content/#video-groups).

### Channels

You should have all your YouTube videos grouped into their own Video Group directories, with the root directory added as a Video Source in [Channels](https://getchannels.com).

For example, if your videos are organized like this:

    /YouTube Videos/Concerts
    /YouTube Videos/SNL Clips
    /YouTube Videos/Music Videos

Then you would add `/YouTube Videos` as a new Video Source in [Channels](https://getchannels.com).

### Pinchflat

Ensure `Download Metadata` is enabled in the Media Profile you are using with Pinchflat. This will create the `info.json` files that youtub3r needs to read the metadata.

[Pinchflat](https://github.com/kieraneglin/pinchflat) defaults to organizing videos for each Source into their own directory. But the default Media Profile puts each video into its own directory. We suggest against this. Instead, format the `output path template` to something like this:

    /{{ source_custom_name }}/{{ upload_yyyy_mm_dd }}-{{ title }}.{{ ext }}

This will result in a directory structure like this:

    /YouTube Videos/Source Name/2024_06_01-Video 1.mp4
    /YouTube Videos/Source Name/2024_06_01-Video 1.info.json
    /YouTube Videos/Source Name/2024_06_12-Video 2.mp4
    /YouTube Videos/Source Name/2024_06_12-Video 2.info.json

This is a required structure for youtub3r to work.

## Usage

### ENV VARS

| ENV VAR         | Description                            | Required | Default |
| --------------- | -------------------------------------- | -------- | ------- |
| SERVER_HOST     | host of Channels DVR Server            | Yes      |         |
| VIDEO_PATH      | root path of your YouTube video groups | Yes      |         |
| WAIT_IN_SECONDS | Number of seconds between scans        | No       | 60      |

### VIDEO_PATH

The path you give Youtub3r must be the path to the root directory of your YouTube video groups. This is the same path you added as a Video Source in Channels.

### CLI

```bash
docker run \
--name youtub3r \
-e SERVER_HOST="192.168.1.2:8089"
-e VIDEO_PATH="/path/to/videos"
youtub3r
```

### Docker Compose

```yaml
version: "3.1"
services:
  youtub34:
    image: youtub3r
    container_name: youtub3r
    environment:
      - SERVER_HOST=192.168.1.2:8089
      - VIDEO_PATH=/path/to/videos
```
