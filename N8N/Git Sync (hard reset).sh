set -euo pipefail
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"
export OCI_CLI_PROFILE="${OCI_CLI_PROFILE:-DEFAULT}"

REPO_DIR="/home/ubuntu/TF-Ephemeral-Windows"
cd "$REPO_DIR"

# Evita concorrência
LOCK=/tmp/tf-ephemeral.lock
exec 200>"$LOCK"
flock -n 200 || { echo "Another run is in progress"; exit 1; }

# Mantém o repo identico ao remoto
git config core.filemode false
git fetch origin
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[ "$CURRENT_BRANCH" != "main" ] && git checkout main || true
git reset --hard origin/main
git clean -fd

echo "Git sync OK"
