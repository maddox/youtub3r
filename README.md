# youtub3r!

This scans a Channels DVR Server instance and attempts to find NFO JSON files to apply to the videos that came from Pinchflat.

### ENV VARS

| ENV VAR         | Description                             | Required | Default |
| --------------- | --------------------------------------- | -------- | ------- |
| SERVER_HOST     | host of Channels DVR Server             | Yes      |         |
| VIDEO_PATH      | path to video files                     | Yes      |         |
| VIDEO_GROUPS    | comma separated list of video group IDs | Yes      |         |
| WAIT_IN_SECONDS | Number of seconds between scans         | No       | 60      |

### CLI

```bash
docker run \
--name youtub3r \
-e SERVER_HOST="192.168.1.2:8089"
-e VIDEO_PATH="/path/to/videos"
-e VIDEO_GROUPS="videos-343kjk34j3k,videos-kjkds343"
jonmaddox/youtub3r
```

### Docker Compose

```yaml
version: "3.1"
services:
  youtub34:
    image: jonmaddox/youtub3r
    container_name: youtub3r
    environment:
      - SERVER_HOST=192.168.1.2:8089
      - VIDEO_PATH=/path/to/videos
      - VIDEO_GROUPS="videos-343kjk34j3k,videos-kjkds343"
```
