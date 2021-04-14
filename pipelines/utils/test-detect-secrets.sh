#!/bin/bash
# Execute test of detect-secrets scan on the repository 
# This bash file will run detect-secrets twice on the repository:
# First pass without scanning the folder tests
# Second pass with tests folder scanning 
# The difference between the number of secrets detected between the second and the first pass 
# should be the number of secrets in the file pipelines/detect-secrets/plugins/tests/tests.txt
# As the file tests.txt could be updated, this information is passed to this bash file as the first argument

set -eu
repoRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 && pwd )"
echo "pwd: $(pwd)"
echo "python version: $(python --version)"
echo "Expected number of secrets in pipelines/detect-secrets/plugins/tests/tests.txt: $1"
# Setting variables used to call detect-secrets
inputPath='$repoRoot/'
excludeFiles='.*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints'
excludeFilesWithoutTest='.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints'
options=' --no-basic-auth-scan  --no-keyword-scan'
optionsv1=' --disable-plugin KeywordDetector --disable-plugin BasicAuthDetector   --disable-filter  detect_secrets.filters.heuristic.is_prefixed_with_dollar_sign --disable-filter  detect_secrets.filters.heuristic.is_sequential_string  --disable-filter   detect_secrets.filters.heuristic.is_templated_secret '
excludedSecretsFile='.secrets.baseline' 

# Installing detect-secret
python -m pip install --upgrade pip
# Get branch detect-secrets version
export $(grep DETECT_SECRETS_BRANCH_VERSION configs/.detect-secrets.cfg)
# Install detect-secrets version 1.0.3 by default
DETECT_SECRETS_VERSION=1.0.3

# if branch version is defined, check local detect-secrets version
if [[ ! -z "$DETECT_SECRETS_BRANCH_VERSION" ]] ; then
    echo "Branch detect-secrets version: $DETECT_SECRETS_BRANCH_VERSION"
    DETECT_SECRETS_VERSION="$DETECT_SECRETS_BRANCH_VERSION"
fi
# Installing detect-secret
echo "Installing tox, pre-commit, detect-secrets version $DETECT_SECRETS_VERSION"
pip install tox==3.21.3 pre-commit==2.10.0  detect-secrets=="$DETECT_SECRETS_VERSION"


echo "detect-secrets version: $(detect-secrets --version)"
if [[ $(detect-secrets --version) < 1 ]] ; then
    cmd="detect-secrets scan --custom-plugins pipelines/detect-secrets/plugins/ $inputPath --exclude-files '$excludeFiles' $options " 
    echo "$cmd"
    if [[ -f "$excludedSecretsFile" ]]; then
        cat "$excludedSecretsFile" | python $repoRoot/pipelines/detect-secrets/displayresults.py  > $repoRoot/pipelines/detect-secrets/excluded_secrets.txt || true
    fi
    resultMin=$(eval "$cmd" | jq ".results[][].type" | wc -l)
    cmd="detect-secrets scan --custom-plugins pipelines/detect-secrets/plugins/ $inputPath --exclude-files '$excludeFilesWithoutTest' $options " 
    resultMax=$(eval "$cmd" | jq ".results[][].type" | wc -l)
    diff=$((resultMax-resultMin))
else
    cmd="detect-secrets scan --plugin '$repoRoot/pipelines/detect-secrets/plugins/azuresas.py' --plugin '$repoRoot/pipelines/detect-secrets/plugins/azuredatabrickstoken.py' --plugin '$repoRoot/pipelines/detect-secrets/plugins/azurestoragekey.py' $inputPath --exclude-files '$excludeFiles' $optionsv1 " 
    echo "$cmd"
    if [[ -f "$excludedSecretsFile" ]]; then
        cat "$excludedSecretsFile" | python $repoRoot/pipelines/detect-secrets/displayresults.py  > $repoRoot/pipelines/detect-secrets/excluded_secrets.txt || true
    fi
    resultMin=$(eval "$cmd" | jq ".results[][].type" | wc -l)
    cmd="detect-secrets scan --plugin '$repoRoot/pipelines/detect-secrets/plugins/azuresas.py' --plugin '$repoRoot/pipelines/detect-secrets/plugins/azuredatabrickstoken.py' --plugin '$repoRoot/pipelines/detect-secrets/plugins/azurestoragekey.py' $inputPath --exclude-files '$excludeFilesWithoutTest' $optionsv1 " 
    resultMax=$(eval "$cmd" | jq ".results[][].type" | wc -l)
    diff=$((resultMax-resultMin))
fi
if [[ $diff == $1 ]]; then
    echo "Test successfull $resultMin secret(s) detected for the first pass, $resultMax secret(s) detected for the second pass, the difference matches with the number of secrets ($1) in the file tests.txt  "
    exit 0
else
    echo "Test failed $resultMin secret(s) detected for the first pass, $resultMax secret(s) detected for the second pass, the difference doesn't match with the number of secrets ($1) in the file tests.txt "
    exit 1
fi