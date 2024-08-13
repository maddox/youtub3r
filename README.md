# nam3r!

This scans a Channels DVR Server instance and attempts to find NFO files to apply to the Files

### ENV VARS

| ENV VAR         | Description                     | Required | Default |
| --------------- | ------------------------------- | -------- | ------- |
| SERVER_HOST     | host of Channels DVR Server     | Yes      |         |
| VIDEO_PATH      | path to video files             | Yes      |         |
| WAIT_IN_SECONDS | Number of seconds between scans | No       | 60      |

### CLI

```bash
docker run \
--name nam3r \
-e SERVER_HOST="192.168.1.2:8089"
-e VIDEO_PATH="/path/to/videos"
jonmaddox/nam3r
```

### Docker Compose

```yaml
version: "3.1"
services:
  nam3r:
    image: jonmaddox/nam3r
    container_name: nam3r
    environment:
      - SERVER_HOST=192.168.1.2:8089
      - VIDEO_PATH=/path/to/videos
```
