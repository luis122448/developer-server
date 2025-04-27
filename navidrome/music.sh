#!/bin/bash

# --- Configuration ---
# !! Adjust these variables for your setup !!
NAVIDROME_MUSIC_PATH="/mnt/server/music"  # Destination for music files
LOG_FILE="/var/log/torrent_copy.log"      # Log file location
POST_DOWNLOAD_DELAY_SECONDS=10            # Delay (secs) after download completion
MUSIC_CATEGORY="music"                    # Category name for music torrents
# --- End Configuration ---

# --- Script Arguments (Expected from Torrent Client) ---
TORRENT_CATEGORY="$1" # $1: Torrent category
DOWNLOAD_PATH="$2"    # $2: Full path to downloaded file/directory
# --- End Script Arguments ---

# Function for logging messages
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# --- Argument Validation ---
if [[ -z "$TORRENT_CATEGORY" || -z "$DOWNLOAD_PATH" ]]; then
  log_message "Error: Missing arguments (Category: '$TORRENT_CATEGORY', Path: '$DOWNLOAD_PATH'). Exiting."
  exit 1
fi

# --- Main Logic ---
log_message "Script triggered. Category: '$TORRENT_CATEGORY', Path: '$DOWNLOAD_PATH'."

if [[ "$TORRENT_CATEGORY" == "$MUSIC_CATEGORY" ]]; then
  log_message "Category matches '$MUSIC_CATEGORY'. Preparing to copy."
  sleep "$POST_DOWNLOAD_DELAY_SECONDS"

  if [[ ! -e "$DOWNLOAD_PATH" ]]; then
    log_message "Error: Download path '$DOWNLOAD_PATH' does not exist. Cannot copy."
    exit 1
  fi

  mkdir -p "$NAVIDROME_MUSIC_PATH"
  if [[ $? -ne 0 ]]; then
      log_message "Error: Could not create destination directory '$NAVIDROME_MUSIC_PATH'."
      exit 1
  fi

  SOURCE_FOR_RSYNC="$DOWNLOAD_PATH"
  if [[ -d "$DOWNLOAD_PATH" ]]; then
    SOURCE_FOR_RSYNC="${DOWNLOAD_PATH}/" # Add trailing slash for directory contents
  elif [[ ! -f "$DOWNLOAD_PATH" ]]; then
     log_message "Error: '$DOWNLOAD_PATH' is not a regular file or directory. Cannot copy."
     exit 1
  fi

  log_message "Executing: rsync -av --ignore-existing '$SOURCE_FOR_RSYNC' '$NAVIDROME_MUSIC_PATH/'"
  rsync -av --ignore-existing "$SOURCE_FOR_RSYNC" "$NAVIDROME_MUSIC_PATH/"
  RSYNC_EXIT_CODE=$?

  if [[ $RSYNC_EXIT_CODE -eq 0 ]]; then
    log_message "Successfully copied '$SOURCE_FOR_RSYNC' to '$NAVIDROME_MUSIC_PATH/'."
  else
    log_message "Error: rsync failed with exit code $RSYNC_EXIT_CODE."
    exit 1
  fi
else
  log_message "Torrent category '$TORRENT_CATEGORY' is not '$MUSIC_CATEGORY'. No action taken."
fi

log_message "Script finished."
exit 0