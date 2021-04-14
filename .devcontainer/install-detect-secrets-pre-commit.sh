#!/bin/bash
# Execute pre-commit install if the configuration files (.secrets.baseline and .pre-commit-config.yaml) are present and the hook is not installed
# The command "pre-commit install" will install the detect-secrets hook to prevent secrets from being committed in the source code. 
# executable
#

set -e
repoRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"

cd "$repoRoot" || true
if [[ -f "$repoRoot"/.pre-commit-config.yaml ]] && [[ -f "$repoRoot"/.secrets.baseline ]] && [[ ! -f "$repoRoot"/.git/hooks/pre-commit ]] ; 
then 
     pre-commit install ; 
fi
