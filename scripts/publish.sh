#!/bin/bash
# publish.sh — regenerates index.html + archive.html from ai-digest-*.html files
# and pushes to GitHub if anything actually changed. Safe to re-run repeatedly:
# no-ops when there's nothing new. macOS-specific (uses BSD `date -j`).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

mkdir -p dailies

# Move any newly-dropped daily files out of the root into dailies/
shopt -s nullglob
new_files=(ai-digest-*.html)
shopt -u nullglob
for f in "${new_files[@]}"; do
  mv "$f" "dailies/$f"
done

shopt -s nullglob
files=(dailies/ai-digest-*.html)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "$(date): no digest files found" >> publish.log
  exit 0
fi

LATEST=$(printf '%s\n' "${files[@]}" | sort | tail -n 1)
cp "$LATEST" index.html

{
  echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>AI Digest Archive</title></head><body>"
  echo "<h1>AI Digest Archive</h1>"
  prev_month=""
  for f in $(printf '%s\n' "${files[@]}" | sort -r); do
    base=$(basename "$f")
    ym=$(echo "$base" | sed -E 's/ai-digest-([0-9]{4})-([0-9]{2})-[0-9]{2}\.html/\1-\2/')
    month=$(date -j -f "%Y-%m" "$ym" "+%B %Y" 2>/dev/null || echo "$ym")
    if [ "$month" != "$prev_month" ]; then
      echo "<h2>$month</h2>"
      prev_month="$month"
    fi
    echo "<p><a href=\"$f\">$base</a></p>"
  done
  echo "</body></html>"
} > archive.html

git add -A
if git diff --cached --quiet; then
  echo "$(date): nothing changed" >> publish.log
  exit 0
fi

git commit -m "Publish digest $(date +%Y-%m-%d)" >> publish.log 2>&1
git push >> publish.log 2>&1
echo "$(date): published $LATEST" >> publish.log
