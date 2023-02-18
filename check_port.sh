#!/bin/bash


# powered by HowHowWen
# Blog : https://how64bit.com
# Mail : blog@how64bit.com


export TIMEOUT_SECONDS=1
export LOCAL_HOST_NAME="$(hostname)"
export DEVICE_PATH_LIST=(
      "/dev/tcp/127.0.0.1/22"
      "/dev/tcp/127.0.0.1/80"
  )

printf "\U1F4DD Test port on ${LOCAL_HOST_NAME}:\n"
for device_path in "${DEVICE_PATH_LIST[@]}"; do
    export HOST=$(echo "$device_path" | cut -d '/' -f 4)
    export PORT=$(echo "$device_path" | cut -d '/' -f 5)
    timeout $TIMEOUT_SECONDS bash -c "echo 'What is up by howhow ...' >${device_path}" 2>/dev/null && \
    printf " \U1F44D Success at $HOST:$PORT" ||  printf " \U1F4DB Failure at $HOST:$PORT"
    echo 
done