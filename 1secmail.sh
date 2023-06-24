#!/bin/bash

if command -v jq > /dev/null 2>&1; then :; else
  echo "jq not installed" 1>&2
  exit 3
fi

usage() {
  echo "Usage: $0 [...options]" 1>&2
  cat 1>&2 << EOM

Options:
  -h              Show this help menu
  -R <count>      Get random email addresses
  -D              Get list of domains
  -e              Email username
  -d              Email domain
  -E              Check emails (-e and -d required)
EOM
  exit 2
}

if [ -z "$*" ]; then
  usage
fi

API="https://www.1secmail.com/api/v1/?action"

EMAIL=""
DOMAIN=""

while getopts "hR:De:d:E" opt; do
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

    D)
      curl -s "$API=getDomainList" | jq -r '.[]'
      ;;

    e)
      if [[ "$OPTARG" =~ @ ]]; then
        IFS="@" read -r EMAIL DOMAIN <<< "$OPTARG"
      else
        EMAIL="$OPTARG"
      fi
      ;;

    d)
      DOMAIN="$OPTARG"
      ;;

    E)
      if [ -z "$EMAIL" ]; then
        echo "Missing email" 1>&2
        exit 1
      fi
      if [ -z "$DOMAIN" ]; then
        echo "Missing domain" 1>&2
        exit 1
      fi

      if [ -z "$OPTARG" ]; then
        curl -s "$API=getMessages&login=$EMAIL&domain=$DOMAIN"
      # else
      #   curl -s "$API=readMessage&login=$EMAIL&domain=$DOMAIN&id=$OPTARG"
      fi
      ;;

    *)
      usage
      ;;
  esac
done
