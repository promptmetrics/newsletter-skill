#!/usr/bin/env sh
# DEPRECATED — kept only so old docs don't break.
#
# The Loops skills (loops-api, loops-cli, loops-lmx, loops-email-sending-best-practices)
# are now VENDORED inside this plugin. Users no longer need to run anything:
#
#   /plugin install promptmetrics-newsletter@promptmetrics
#
# installs them automatically. There is no separate curl/npx step.
#
# Maintainers re-syncing the vendored skills from upstream should use:
#
#   ./skills/newsletter/scripts/sync-loops-skills.sh [ref]   # default: v0.2.0
#
# This stub does nothing and exits 0.
echo "install-loops-skills.sh is deprecated: the Loops skills now ship bundled"
echo "with the promptmetrics-newsletter plugin. Install the plugin instead:"
echo "  /plugin install promptmetrics-newsletter@promptmetrics"
echo "(Maintainers syncing upstream: use scripts/sync-loops-skills.sh.)"
exit 0