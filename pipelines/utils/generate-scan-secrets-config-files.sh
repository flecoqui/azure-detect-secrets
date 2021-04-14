#!/bin/bash
# Execute detect-secrets scan on the repository to detect secrets
#

set -e
repoRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 && pwd )"

# Setting variables used to call detect-secrets
inputPath='./'
excludeFiles='.*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints'
excludeFilesWithoutTests='.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints'
options=' --no-basic-auth-scan  --no-keyword-scan'
optionsv1=' --disable-plugin KeywordDetector --disable-plugin BasicAuthDetector   --disable-filter  detect_secrets.filters.heuristic.is_prefixed_with_dollar_sign --disable-filter  detect_secrets.filters.heuristic.is_sequential_string  --disable-filter   detect_secrets.filters.heuristic.is_templated_secret '
excludedSecretsFile='.secrets.baseline' 


# Get branch detect-secrets version
export "$(grep DETECT_SECRETS_BRANCH_VERSION "$repoRoot"/configs/.detect-secrets.cfg)"
# Get branch detect-secrets version
LOCAL_DETECT_SECRETS_VERSION=$(detect-secrets --version)
# Install detect-secrets version 1.0.3 by default
DETECT_SECRETS_VERSION=1.0.3

echo "Branch detect-secrets version: $DETECT_SECRETS_BRANCH_VERSION"
echo "Local detect-secrets version: $LOCAL_DETECT_SECRETS_VERSION"

# if branch version is defined, check local detect-secrets version
if [[ -n "$DETECT_SECRETS_BRANCH_VERSION" ]] ; then
    DETECT_SECRETS_VERSION="$DETECT_SECRETS_BRANCH_VERSION"
fi
if [[ "$LOCAL_DETECT_SECRETS_VERSION" != "$DETECT_SECRETS_VERSION" ]] ; then
    # Installing detect-secret
    echo "Installing tox, pre-commit, detect-secrets"
    pip install tox==3.21.3 pre-commit==2.10.0  detect-secrets=="$DETECT_SECRETS_VERSION"
    LOCAL_DETECT_SECRETS_VERSION=$(detect-secrets --version)
fi

if [[ "$LOCAL_DETECT_SECRETS_VERSION" != "$DETECT_SECRETS_VERSION" ]] ; then
    # Installing detect-secret
    echo "Error while installing detect-secrets version: $DETECT_SECRETS_VERSION"
    exit 1
fi

# removing exting files
rm "$repoRoot"/.secrets.baseline >/dev/null 2>&1|| true
rm "$repoRoot"/.pre-commit-config.yaml >/dev/null 2>&1 || true

# Check if .secrets.baseline exists
# if not create .secrets.baseline
if [[ ! -f "$repoRoot"/.secrets.baseline ]]; then
    echo "Creating file .secrets.baseline..."
    echo "Detect-secrets version: $(detect-secrets --version)"
    # shellcheck disable=SC2071
    if [[ $(detect-secrets --version) < 1 ]] ; then
        cmd="detect-secrets scan --custom-plugins ./pipelines/detect-secrets/plugins/ $inputPath   --exclude-files '$excludeFiles' $options"
        eval "$cmd" > .secrets.baseline
    else
        cmd="detect-secrets scan --plugin ./pipelines/detect-secrets/plugins/azuresas.py --plugin ./pipelines/detect-secrets/plugins/azuredatabrickstoken.py --plugin ./pipelines/detect-secrets/plugins/azurestoragekey.py  $inputPath   --exclude-files '$excludeFiles' $optionsv1" 
        eval "$cmd" > .secrets.baseline
    fi
    echo "File .secrets.baseline created"
    echo "Don't forget to add the file in the repository"
    echo "git add $repoRoot/.secrets.baseline"
    echo "git commit -m  \"add file .secrets.baseline\" "
fi

if [[ ! -f "$repoRoot"/.pre-commit-config.yaml ]]; then
    echo "Creating file .pre-commit-config.yaml..."
    # shellcheck disable=SC2071
    if [[ $(detect-secrets --version) < 1 ]] ; then
    cat > .pre-commit-config.yaml << EOF
repos:
-   repo: https://github.com/Yelp/detect-secrets.git
    rev: v0.14.3
    hooks:
    -   id: detect-secrets
        args: ['--baseline', '.secrets.baseline', '--custom-plugins', './pipelines/detect-secrets/plugins', '--no-basic-auth-scan','--no-keyword-scan' ]
        exclude: .*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints
EOF
    else
    cat > .pre-commit-config.yaml << EOF
repos:
-   repo: https://github.com/Yelp/detect-secrets.git
    rev: v1.0.3
    hooks:
    -   id: detect-secrets
        args: ['--baseline', '.secrets.baseline', '--plugin', './pipelines/detect-secrets/plugins/azuresas.py','--plugin', './pipelines/detect-secrets/plugins/azuredatabrickstoken.py','--plugin', './pipelines/detect-secrets/plugins/azurestoragekey.py','--disable-plugin', 'KeywordDetector', '--disable-plugin', 'BasicAuthDetector','--disable-filter',  'detect_secrets.filters.heuristic.is_prefixed_with_dollar_sign', '--disable-filter',  'detect_secrets.filters.heuristic.is_sequential_string',  '--disable-filter',   'detect_secrets.filters.heuristic.is_templated_secret' ]
        exclude: .*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints
EOF
    fi
    # uninstall possible existing pre-commit
    pre-commit uninstall
    pre-commit install
    echo "File .pre-commit-config.yaml created"
    echo "Don't forget to add the file in the repository"
    echo "git add $repoRoot/.pre-commit-config.yaml"
    echo "git commit -m  \"add file .pre-commit-config.yaml\" "
fi


echo "python version: $(python --version)"
echo "detect-secrets version: $(detect-secrets --version)"
# Remove any previous result file
rm -f "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt 
python "$repoRoot"/pipelines/detect-secrets/displayresults.py < "$repoRoot"/.secrets.baseline   > "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt || true
echo ""
echo "TEST DETECT-SECRETS: excluding tests files: 0 secret should be discovered"
echo ""
# shellcheck disable=SC2071
if [[ $(detect-secrets --version) < 1 ]] ; then
    cmd="detect-secrets scan --custom-plugins "$repoRoot"/pipelines/detect-secrets/plugins/ "$repoRoot"/  --exclude-files '$excludeFiles' $options" 
    eval "$cmd" <<< '' | python "$repoRoot"/pipelines/detect-secrets/displayresults.py "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt  || true
else
    cmd="detect-secrets scan --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azuresas.py --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azuredatabrickstoken.py --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azurestoragekey.py  "$repoRoot"/  --exclude-files '$excludeFiles' $optionsv1"
    eval "$cmd" <<< '' | python "$repoRoot"/pipelines/detect-secrets/displayresults.py "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt  || true
fi


echo ""
echo "TEST DETECT-SECRETS: secrets in tests.txt should be discovered"
echo ""
# shellcheck disable=SC2071
if [[ $(detect-secrets --version) < 1 ]] ; then
    cmd="detect-secrets scan --custom-plugins "$repoRoot"/pipelines/detect-secrets/plugins/ "$repoRoot"/  --no-basic-auth-scan  --no-keyword-scan --exclude-files '$excludeFilesWithoutTests' $options"
    eval "$cmd"  <<< '' | python "$repoRoot"/pipelines/detect-secrets/displayresults.py "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt  || true
else
    cmd="detect-secrets scan --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azuresas.py --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azuredatabrickstoken.py --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azurestoragekey.py  "$repoRoot"/  --exclude-files '$excludeFilesWithoutTests' $optionsv1"
    eval "$cmd"  <<< '' | python "$repoRoot"/pipelines/detect-secrets/displayresults.py "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt  || true
fi
# Remove result file
rm -f "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt 
