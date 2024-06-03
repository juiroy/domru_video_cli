#!/bin/bash

credentials_dir="./credentials"
session_dir="./sessions"

# Default values
light_stream=0
format=H264

send_post_request() {
    local url="$1"
    shift

    curl -s -X POST "$url" -d "$@" -H "Content-Type: application/x-www-form-urlencoded"
}


get_session_file_location() {
  local login="$1"
  
  echo "$session_dir/$login"
}

get_password() {
  local login="$1"

  local password_file="$credentials_dir/$login"

  if [ ! -r "$password_file" ]; then
    exit 1
  fi
  
  read -r password < "$password_file"
  echo "$password"
}

save_session() {
    local login="$1"
    shift
    local session="$1"

    local session_file=$(get_session_file_location $login)
    echo "$session" > "$session_file"
}

check_session() {
  local session_id="$1"
  local response=$(send_post_request "https://video.domru.ru/api/vs/getcurrenttime" "SessionID=$session_id")
  substr="ServerTime"
  if [[ $response == *"ServerTime"* ]]; then
      return 0
    else
      return 1
  fi
}

authenticate() {
  local login="$1"
  shift
  local password="$1"

  local auth_response=$(send_post_request "https://video.domru.ru/api/vs/login" "Login=$login&Password=$password")
  local session_id=$(echo "$auth_response" | grep -o '"SessionID":[^,]*' | sed 's/.*"SessionID":"\([^"]*\)".*/\1/')
  if [ -r "$session_id" ]; then
    exit 1
  fi
  echo "$session_id"
}

read_session() {
  local login="$1"

  local session_file=$(get_session_file_location $login)

  if [ ! -r "$session_file" ]; then
    exit 1
  fi
  
  read -r session < "$session_file"
  echo "$session"
}

get_stream_url() {
  local session_id="$1"
  shift
  local camera_id="$1"
  shift
  local format="$1"
  shift
  local light_stream="$1"

  get_stream_response=$(send_post_request "https://video.domru.ru/api/vs/gettranslationurl" "SessionID=$session_id&CameraID=$camera_id&Format=$format&LightStream=$light_stream")
  echo "$get_stream_response" | grep -o '"URL":[^,]*' | sed 's/.*"URL":"\([^"]*\)".*/\1/'
}

main () {
  if [ ! -d "$session_dir" ]; then
    mkdir "$session_dir"
  fi

  # Parse named arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --login=*)
        login="${1#*=}"
        shift
        ;;
      --camera_id=*)
        camera_id="${1#*=}"
        shift
        ;;
      --format=*)
        format="${1#*=}"
        shift
        ;;
      --light_stream=*)
        light_stream="${1#*=}"
        shift
        ;;
      *)
        printf "Invalid argument: $1\n"
        exit 1
        ;;
    esac
  done

  # Check if required arguments are provided
  if [ -z "$login" ] || [ -z "$camera_id" ] || [ -z "$format" ]; then
    echo "Usage: $0 --login=<login> --camera_id=<camera_id> [--format=<format>] [--light_stream=<light_stream>]"
    exit 1
  fi

  password=$(get_password "$login")
  if [ -z "$password" ]; then
    echo "no password file"
    exit 1
  fi

  session_id=$(read_session $login)

  # If no saved session found, or saved session invalid/expired -> authenticate and save session
  if [ -z "$session_id" ] ||  ! check_session $session_id; then
    session_id=$(authenticate "$login" "$password")
    if [ -r "$session_id" ]; then
      exit 1
    fi
    $(save_session "$login" "$session_id")
  fi

  # Output the URL
  get_stream_url $session_id $camera_id $format $light_stream
}

echo $(main $@)