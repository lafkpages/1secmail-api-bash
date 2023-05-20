#!/bin/bash

if command -v jq > /dev/null 2>&1; then :; else
  echo "jq not installed" 1>&2
  exit 3
fi

usage() {
  echo "Usage: $0 [-R count?]" 1>&2
  exit 2
}

if [ -z "$*" ]; then
  usage
fi

API="https://www.1secmail.com/api/v1/?action"

while getopts "hR:" opt; do
  case "$opt" in
    h)
      usage
      ;;

    R)
      count="$OPTARG"
      if [ -z "$count" ]; then
        count="1"
      fi

      curl -s "$API=genRandomMailbox&count=$count" | jq -r '.[]'
      ;;

    *)
      usage
      ;;
  esac
done
