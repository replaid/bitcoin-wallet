#!/bin/bash
# wallet-docker.sh

case "$1" in
  bundle)
    docker compose run --rm --entrypoint "bundle" wallet "${@:2}"
    ;;
  test)
    docker compose run --rm test
    ;;
  help|balance)
    docker compose run --rm wallet "$1"
    ;;
  send)
    if [ -z "$2" ] || [ -z "$3" ]; then
      echo "Usage: ./wallet-docker.sh send <amount> <address>"
      exit 1
    fi
    docker compose run --rm wallet send "$2" "$3"
    ;;
  *)
    exit 1
    ;;
esac
