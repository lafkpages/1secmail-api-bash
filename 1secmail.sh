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
  -l              Check emails (-e required)
  -E <id>         Check email by ID
EOM
  exit 2
}

if [ -z "$*" ]; then
  usage
fi

API="https://www.1secmail.com/api/v1/?action"

EMAIL=""
DOMAIN=""

requireEmail() {
  if [ -z "$EMAIL" ]; then
    echo "Missing email" 1>&2
    exit 1
  fi
}

requireDomain() {
  if [ -z "$DOMAIN" ]; then
    echo "Missing domain" 1>&2
    exit 1
  fi
}

setEmail() {
  IFS="@" read -r EMAIL DOMAIN <<< "$1"
}

if [ -n "$ONESECMAIL" ]; then
  setEmail "$ONESECMAIL"
  requireEmail
  requireDomain
fi

while getopts "hR:De:d:lE:" opt; do
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
        setEmail "$OPTARG"
        requireEmail
        requireDomain
      else
        EMAIL="$OPTARG"
        requireEmail
      fi
      ;;

    d)
      DOMAIN="$OPTARG"
      requireDomain
      ;;

    l)
      requireEmail
      requireDomain

      curl -s "$API=getMessages&login=$EMAIL&domain=$DOMAIN"

      echo

      ;;

    E)
      requireEmail
      requireDomain

      if [ -z "$OPTARG" ]; then
        echo "Missing email ID" 1>&2
        exit 1
      fi

      curl -s "$API=readMessage&login=$EMAIL&domain=$DOMAIN&id=$OPTARG"

      ;;

    *)
      usage
      ;;
  esac
done
