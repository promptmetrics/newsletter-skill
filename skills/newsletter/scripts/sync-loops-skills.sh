#!/usr/bin/env sh
# Maintainer-only: re-sync the four vendored Loops skills from upstream.
# NOT a user prerequisite — the skills ship bundled with the plugin, so
# `/plugin install promptmetrics-newsletter@promptmetrics` brings them along.
#
# Usage:
#   ./skills/newsletter/scripts/sync-loops-skills.sh [ref]   # default: v0.2.0
#
# After syncing, review the diff and commit. If you sync to a ref other than
# the one pinned in NOTICE, update NOTICE (and this default) to match.
set -eu

REF="${1:-v0.2.0}"
SRC_REPO="https://github.com/Loops-so/skills.git"
SKILLS_DIR="$(cd "$(dirname "$0")/../.." && pwd)"   # <repo>/skills
SKILLS="loops-api loops-cli loops-lmx loops-email-sending-best-practices"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching Loops skills @ $REF..."
git clone --depth 1 --branch "$REF" "$SRC_REPO" "$TMP/src" >/dev/null

for s in $SKILLS; do
  echo "  syncing $s"
  rm -rf "$SKILLS_DIR/$s"
  cp -R "$TMP/src/skills/$s" "$SKILLS_DIR/$s"
  cp "$TMP/src/LICENSE" "$SKILLS_DIR/$s/LICENSE"
  # Inject the attribution header after the YAML frontmatter.
  awk -v ref="$REF" '
    NR == 1 && /^---/ { fm = 1; print; next }
    fm == 1 && /^---/ {
      print; print "";
      print "<!-- Vendored from https://github.com/Loops-so/skills @ " ref " (MIT, Copyright (c) 2026 Loops). -->";
      print "<!--      Synced via skills/newsletter/scripts/sync-loops-skills.sh — do not edit here; update upstream and re-sync. -->";
      fm = 0; next
    }
    { print }
  ' "$SKILLS_DIR/$s/SKILL.md" > "$SKILLS_DIR/$s/SKILL.md.tmp" && mv "$SKILLS_DIR/$s/SKILL.md.tmp" "$SKILLS_DIR/$s/SKILL.md"
done

echo ""
echo "Synced 4 skills @ $REF into $SKILLS_DIR."
echo "Next: review with 'git diff skills/loops-* NOTICE', then commit."
echo "If $REF != v0.2.0, update the pinned ref in NOTICE and this script's default."