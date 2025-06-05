# Dom.ru Video CLI

This repository contains a small Bash script for obtaining video stream URLs from Dom.ru cameras. The script was originally developed to allow the [go2rtc](https://github.com/AlexxIT/go2rtc) project to integrate with Dom.ru's video surveillance service.

## Requirements
- `bash`
- `curl`
- standard Unix tools: `grep`, `sed`

## Setup
1. Place your password in a file named after your login inside the `credentials` directory. The script expects this directory to be alongside `dom_ru.sh`.
2. Session cookies are cached in the `sessions` directory which will be created automatically.

## Usage
Run the script with required arguments:

```bash
./dom_ru.sh --login=<login> --camera_id=<id> [--format=<format>] [--light_stream=<0|1>]
```

- `--login` – Dom.ru account login (used to locate the credential file).
- `--camera_id` – numeric identifier of the camera.
- `--format` – stream format such as `H264`.
- `--light_stream` – optional flag for lower bandwidth stream, `0` by default.

The script prints the resulting streaming URL.

## Examples

```bash
./dom_ru.sh --login=user@example --camera_id=1234 --format=H264
```

When integrating with go2rtc, add an `echo` source to the configuration that runs this script. The `--storage` flag should point to the directory that contains the `credentials` and `sessions` folders:

```yaml
streams:
  domru_cam:
    - echo: /scripts/dom_ru/dom_ru.sh --login=user@example --camera_id=1234 --storage=/path/to/secrets/storage
```

Because [Frigate](https://frigate.video/) relies on go2rtc for stream handling, you can reference the same configuration entry to add a Dom.ru camera.


