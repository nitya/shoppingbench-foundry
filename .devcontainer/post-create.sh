#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Creating virtual environment (.venv)"
python -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip --quiet

echo "==> Installing project with agent and dev extras, plus workshop tools"
pip install -e ".[agents,dev]" -r .devcontainer/requirements.txt --quiet

echo "==> Registering Jupyter kernel"
python -m ipykernel install --user --name shoppingbench --display-name "Python (shoppingbench)"

echo "==> Installing the azd AI agents extension (needed to deploy hosted agents)"
azd extension install azure.ai.agents >/dev/null 2>&1 \
  || azd extension upgrade azure.ai.agents >/dev/null 2>&1 \
  || echo "    warning: could not install azure.ai.agents; run 'azd extension install azure.ai.agents' later"

# The Foundry Toolkit extension ships the microsoft-foundry skill; this is the fallback.
if [[ ! -d "$HOME/.agents/skills/microsoft-foundry" ]]; then
  echo "==> Installing the microsoft-foundry skill (fallback)"
  timeout 180 npx --yes skills add https://github.com/microsoft/azure-skills --skill microsoft-foundry </dev/null \
    || echo "    warning: skill install skipped; the Foundry Toolkit extension also provides it"
fi

echo "==> Quick self-check"
python - <<'PY'
import importlib
for module in ("shoppingbench_foundry.grading", "shoppingbench_foundry.store", "azure.ai.projects"):
    importlib.import_module(module)
print("    imports ok")
PY

cat <<'MSG'

Environment ready.
  - Python venv:   .venv (auto-activated in new terminals)
  - Kernel:        Python (shoppingbench)
  - Next step:     open .github/planning/WALKTHROUGH.md
MSG
