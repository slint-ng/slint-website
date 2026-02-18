#!/bin/sh
# This script builds POT files from source asciidoc text files in $LOCAL_MIRROR

LOCAL_MIRROR=~/slint-ng.org
TRANSLATIONS_DIR=~/MYENV/slintwebsite/translations

for PAGE_WHOLE_PATH in "$TRANSLATIONS_DIR"/slintwebsite.*pot; do
  [ -e "$PAGE_WHOLE_PATH" ] || continue

  PAGE_WHOLE_NAME=`basename "$PAGE_WHOLE_PATH"`
  PAGE_POT=${PAGE_WHOLE_NAME#slintwebsite.}
  PAGE=${PAGE_POT%pot}
  PAGE_SOURCE=$LOCAL_MIRROR/$PAGE.en.txt

  if [ -f "$LOCAL_MIRROR/po/$PAGE/$PAGE.pot.orig" ]; then
    echo "Please remove $LOCAL_MIRROR/po/$PAGE/$PAGE.pot.orig then restart the script"
    exit 1
  fi

  if [ -f "$LOCAL_MIRROR/po/$PAGE/$PAGE.pot" ]; then
    mv "$LOCAL_MIRROR/po/$PAGE/$PAGE.pot" "$LOCAL_MIRROR/po/$PAGE/$PAGE.pot.orig"
  fi

  po4a-gettextize -f asciidoc -m "$PAGE_SOURCE" -p "$LOCAL_MIRROR/po/$PAGE/$PAGE.pot" -M UTF-8
done
