#!/bin/bash
# publish.sh — regenerates index.html + archive.html from ai-digest-*.html files
# and pushes to GitHub if anything actually changed. Safe to re-run repeatedly:
# no-ops when there's nothing new. macOS-specific (uses BSD `date -j`).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# ponytail: launchd runs every 5 min; a lock older than that is dead, not in-use
if [ -f .git/index.lock ] && [ $(( $(date +%s) - $(stat -f %m .git/index.lock) )) -gt 120 ]; then
  rm -f .git/index.lock
fi

mkdir -p dailies

# Move any newly-dropped daily files out of the root into dailies/
shopt -s nullglob
new_files=(ai-digest-*.html)
shopt -u nullglob
if [ ${#new_files[@]} -gt 0 ]; then
  for f in "${new_files[@]}"; do
    mv "$f" "dailies/$f"
  done
fi

shopt -s nullglob
files=(dailies/ai-digest-*.html)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "$(date): no digest files found" >> publish.log
  exit 0
fi

LATEST=$(printf '%s\n' "${files[@]}" | sort | tail -n 1)
cp "$LATEST" index.html

# Add a right-aligned Archive pill to the source-filter row. Anchored on the
# opening tag, not the pills themselves — those vary day to day depending on
# which sources had content. CSS order:999 + margin-left:auto puts this pill
# last and pushed right regardless of how many source pills render that day.
sed -i '' '/<div class="source-bar">/a\
<a href="archive.html" class="filter-pill" style="order:999;margin-left:auto;text-decoration:none;opacity:0.6;background:var(--color-bg-page);color:var(--color-text-secondary);border-color:var(--color-border);">📁 Archive</a>
' index.html

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
