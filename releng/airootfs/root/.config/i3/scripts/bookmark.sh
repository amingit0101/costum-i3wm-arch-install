#!/bin/bash

BOOKMARK_FILE="$HOME/.bookmarks"

# Create bookmark file if it doesn't exist
touch "$BOOKMARK_FILE"

# Function to add bookmark
add_bookmark() {
  URL=$(xclip -selection clipboard -o 2>/dev/null || xsel --clipboard --output 2>/dev/null)

  if [ -n "$URL" ]; then
    NAME=$(echo "$URL" | dmenu -p "Name for bookmark:")
    if [ -n "$NAME" ]; then
      echo "$NAME|$URL" >>"$BOOKMARK_FILE"
      notify-send "📑 Bookmark Added" "$NAME"
    fi
  else
    notify-send "Error" "Clipboard is empty"
  fi
}

# Function to search and open bookmarks
search_bookmarks() {
  if [ ! -s "$BOOKMARK_FILE" ]; then
    notify-send "No Bookmarks" "Add with Mod4+Shift+b"
    exit 1
  fi

  SELECTED=$(cat "$BOOKMARK_FILE" | cut -d'|' -f1 | dmenu -p "Open bookmark:")

  if [ -n "$SELECTED" ]; then
    URL=$(grep "^$SELECTED|" "$BOOKMARK_FILE" | cut -d'|' -f2)
    xdg-open "$URL"
  fi
}

# Main menu
case "$1" in
-a) add_bookmark ;;
*) search_bookmarks ;;
esac
