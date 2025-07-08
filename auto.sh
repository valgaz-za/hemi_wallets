#!/bin/bash

set -e  # Exit on error

# === CONFIGURATION ===
REPO_DIR="$(pwd)"           # Change if needed: /path/to/your/repo
FILE_NAME="README.md"       # File to modify
START_DATE="2024-01-01"     # Date range start
END_DATE="2025-07-01"       # Date range end
COMMIT_COUNT=120            # Number of distinct commit days

# === CHECK REPO ===
cd "$REPO_DIR"

if [ ! -d ".git" ]; then
  echo "❌ Not a git repository!"
  exit 1
fi

if [ ! -f "$FILE_NAME" ]; then
  touch "$FILE_NAME"
  echo "# Auto Commit Log" >> "$FILE_NAME"
fi

# === GENERATE UNIQUE DATES ===
echo "🔧 Generating $COMMIT_COUNT unique commit dates..."

start_ts=$(date -d "$START_DATE" +%s)
end_ts=$(date -d "$END_DATE" +%s)
days_diff=$(( (end_ts - start_ts) / 86400 ))

if [ "$days_diff" -lt "$COMMIT_COUNT" ]; then
  echo "❌ Date range too short. Must be at least $COMMIT_COUNT days."
  exit 1
fi

# Shuffle and pick 120 unique offsets
commit_days=($(seq 0 $days_diff | shuf -n $COMMIT_COUNT | sort -n))
sorted_days=()
for offset in "${commit_days[@]}"; do
  day=$(date -d "$START_DATE +$offset day" +"%Y-%m-%d")
  sorted_days+=("$day")
done

# === MAKE COMMITS ===
echo "📦 Making $COMMIT_COUNT backdated commits..."

i=1
for day in "${sorted_days[@]}"; do
  echo "Commit #$i on $day" >> "$FILE_NAME"
  git add "$FILE_NAME"

  COMMIT_TIME="${day}T12:00:00"
  GIT_AUTHOR_DATE="$COMMIT_TIME" GIT_COMMITTER_DATE="$COMMIT_TIME" \
    git commit -m "Backdated Commit #$i on $day"

  ((i++))
done

# === PUSH COMMITS ===
echo "🚀 Pushing commits to GitHub..."
git push

echo "✅ All $COMMIT_COUNT commits complete and pushed!"
