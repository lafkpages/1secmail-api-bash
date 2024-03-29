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

VERBOSE="0"

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

# Verbose echo, only if VERBOSE is 1
vecho() {
  if [ "$VERBOSE" = "1" ]; then
    echo "$@"
  fi
}

if [ -n "$ONESECMAIL" ]; then
  setEmail "$ONESECMAIL"
  requireEmail
  requireDomain
fi

while getopts "vhR:De:d:lE:" opt; do
  case "$opt" in
    v)
      VERBOSE="1"
      ;;

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

      vecho "Listing emails for $EMAIL@$DOMAIN"

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

      vecho "Getting email ID $OPTARG from $EMAIL@$DOMAIN"

      curl -s "$API=readMessage&login=$EMAIL&domain=$DOMAIN&id=$OPTARG"

      echo

      ;;

    *)
      usage
      ;;
  esac
done
