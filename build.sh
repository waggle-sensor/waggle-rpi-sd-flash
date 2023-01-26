#!/bin/bash -e

print_help() {
  echo """
usage: build.sh [-a]

Create a RPI SD card image to be flashed to configure the RPI for PxE boot mode.

  -a : run in analysis mode to enable analyzing the candidate RPI image
  -? : print this help menu
"""
}

ANALYSIS_MODE=
TTY=
while getopts "a?" opt; do
  case $opt in
    a) # analysis mode
      echo "** Enable Analysis Mode **"
      ANALYSIS_MODE=1
      TTY="-it"
      ;;
    ?|*)
      print_help
      exit 1
      ;;
  esac
done

get_version_long() {
  sha=$(git rev-parse --short HEAD)
  if [ -n "${sha}" ]; then
    sha="-${sha}"
  fi
  git describe --tags --long --dirty 2>/dev/null || echo "v0.0.0${sha}"
}

trim_version_prefix() {
  sed -e 's/^v//'
}

# determine version
VERSION_LONG=$(get_version_long | trim_version_prefix)
echo "VERSION_LONG: ${VERSION_LONG}"

docker build -t pi_sdflash:latest .
docker run ${TTY} --rm --privileged \
    -v "$PWD:/repo" \
    -e VERSION_LONG=$VERSION_LONG \
    -e PAUSE=$ANALYSIS_MODE \
    pi_sdflash:latest
