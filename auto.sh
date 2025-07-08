#!/bin/bash

set -e

# === CONFIGURATION ===
FILE_NAME="README.md"

# === ASK USER FOR START DATE ===
read -p "📅 Enter the starting date (dd/mm/yyyy): " input_date

# Convert and validate
day=$(echo "$input_date" | cut -d'/' -f1)
month=$(echo "$input_date" | cut -d'/' -f2)
year=$(echo "$input_date" | cut -d'/' -f3)

START_DATE=$(date -d "$year-$month-$day" +%Y-%m-%d 2>/dev/null)

if [ -z "$START_DATE" ]; then
  echo "❌ Invalid date format. Please use dd/mm/yyyy"
  exit 1
fi

# === ASK FOR COMMIT COUNT ===
read -p "🔢 Enter how many distinct days you want to commit (e.g., 30 / 60 / 120): " COMMIT_COUNT

# Validate it's a number
if ! [[ "$COMMIT_COUNT" =~ ^[0-9]+$ ]]; then
  echo "❌ Invalid number. Please enter a valid numeric value."
  exit 1
fi

echo "✅ Starting from $START_DATE, committing for $COMMIT_COUNT consecutive unique days..."

# === PREP FILE ===
if [ ! -f "$FILE_NAME" ]; then
  echo "# Auto Commit Log" > "$FILE_NAME"
fi

# === MAKE COMMITS ===
i=1
for ((offset=0; offset<COMMIT_COUNT; offset++)); do
  commit_date=$(date -d "$START_DATE +$offset day" +%Y-%m-%d)

  echo "Commit #$i on $commit_date" >> "$FILE_NAME"
  git add "$FILE_NAME"

  COMMIT_TIME="${commit_date}T12:00:00"
  GIT_AUTHOR_DATE="$COMMIT_TIME" GIT_COMMITTER_DATE="$COMMIT_TIME" \
    git commit -m "Backdated Commit #$i on $commit_date"

  ((i++))
done

# === PUSH TO GITHUB ===
echo "🚀 Pushing all commits to GitHub..."
git push

echo "✅ Success! $COMMIT_COUNT commits created from $START_DATE onward!"
