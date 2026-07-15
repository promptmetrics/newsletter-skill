#!/usr/bin/env sh
# Installs Loops' official agent skills (API, LMX, CLI, Email best-practices)
# into this project. The PromptMetrics newsletter skill is a thin layer on top
# of these — it does not hand-roll raw REST.
#
# Source: https://loops.so/docs/skills
set -e

echo "Installing Loops official skills..."
curl -fsSL https://install.loops.so/skills | sh

echo ""
echo "Installed Loops skills should now include:"
echo "  - loops-api        (REST endpoints: campaigns, email-messages, lists, guardian, uploads)"
echo "  - loops-lmx        (Loops Markup eXpressions component reference)"
echo "  - loops-cli        (CLI wrappers)"
echo "  - loops-email      (email best-practices: dark mode, client rendering, accessibility)"
echo ""
echo "Next: store your Loops API key with:"
echo "  ${CLAUDE_SKILL_DIR:-./skills/newsletter}/scripts/loops-key.sh set"
echo "then complete the one-time Loops UI setup (onboarding) before running the newsletter skill."