#!/bin/bash
#
# executable
#
set -e
repoRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 && pwd )"
echo "repoRoot: $repoRoot"
# check that no credentials are to be committed

# folder with update is the current folder. This is where .git folder must be
updateFolder=${1:-$(pwd)}
echo "Current folder: $updateFolder"

# destination branch name
destBranchName=${2:-main}
destBranchName=${destBranchName#"refs/heads/"}
echo "Destination branch: $destBranchName"

# source branch name
srcBranchName=${3:-$(git status --branch --porcelain=v2 | head -2 | tail -1 | awk '{print $3}')}
srcBranchName=${srcBranchName#"refs/heads/"}
echo "Source branch: $srcBranchName"


if [[ ! -d "${updateFolder}/.git" ]]; then
    echo "update folder ${updateFolder} must have a .git folder"
    exit 1
fi

echo "will check that current update does not have secrets"
echo "update folder: ${updateFolder}"
echo "destination branch name: ${destBranchName}"
echo "source      branch name: ${srcBranchName}"

# Installing detect-secret
# Get branch detect-secrets version
export "$(grep DETECT_SECRETS_BRANCH_VERSION "$repoRoot"/configs/.detect-secrets.cfg)"
# Install detect-secrets version 1.0.3 by default
DETECT_SECRETS_VERSION=1.0.3

# if branch version is defined, check local detect-secrets version
if [[ -n "$DETECT_SECRETS_BRANCH_VERSION" ]] ; then
    echo "Branch detect-secrets version: $DETECT_SECRETS_BRANCH_VERSION"
    DETECT_SECRETS_VERSION="$DETECT_SECRETS_BRANCH_VERSION"
fi
# Installing detect-secret
echo "Installing tox, pre-commit, detect-secrets version $DETECT_SECRETS_VERSION"
pip install tox==3.21.3 pre-commit==2.10.0  detect-secrets=="$DETECT_SECRETS_VERSION"


if [[ $srcBranchName == '(detached)' ]] ; then
    echo "The source branch is not defined, the pipeline has been launched manually"
    echo "The pipeline will scan secret in the whole repository"
    # Remove any previous result file
    rm -f "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt 
    python "$repoRoot"/pipelines/detect-secrets/displayresults.py < "$repoRoot"/.secrets.baseline  > "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt || true
    # shellcheck disable=SC2071
    if [[ $(detect-secrets --version) < 1 ]] ; then
        detect-secrets scan --custom-plugins "$repoRoot"/pipelines/detect-secrets/plugins/ "$repoRoot"/ --exclude-files ".*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints"   --no-basic-auth-scan  --no-keyword-scan  <<< '' | python "$repoRoot"/pipelines/detect-secrets/displayresults.py "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt 
    else
        detect-secrets scan --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azuresas.py --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azuredatabrickstoken.py --plugin "$repoRoot"/pipelines/detect-secrets/plugins/azurestoragekey.py "$repoRoot"/ --exclude-files ".*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints"   --disable-plugin KeywordDetector --disable-plugin BasicAuthDetector   --disable-filter  detect_secrets.filters.heuristic.is_prefixed_with_dollar_sign --disable-filter  detect_secrets.filters.heuristic.is_sequential_string  --disable-filter   detect_secrets.filters.heuristic.is_templated_secret  <<< '' | python "$repoRoot"/pipelines/detect-secrets/displayresults.py "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt 
    fi

    rm -f "$repoRoot"/pipelines/detect-secrets/excluded_secrets.txt 

    exit 0
fi

# temp folder where we will copy current repo
tmpFolder=$(mktemp -d)

cp -R "$updateFolder" "$tmpFolder"
updateFolderBasename=$(basename "${updateFolder}")
pushd "$tmpFolder" || exit

# provide default git config
if [[ "$(git config -l | grep -c user.email)" == "0" ]]; then
    git config --global user.email "devops-pipeline@mlops.invalid"
fi
if [[ "$(git config -l | grep -c user.name )" == "0" ]]; then
    git config --global user.name "devops pipeline"
fi

# install detect-secrets hook in this copy of the git repo
#pip install virtualenv
#virtualenv env1
#source env1/bin/activate


cd "$updateFolderBasename" || exit

git checkout "$srcBranchName"

if [[ ! -f .secrets.baseline ]]; then
    echo "Updating .secrets.baseline"
    # shellcheck disable=SC2071
    if [[ $(detect-secrets --version) < 1 ]] ; then
        detect-secrets scan --custom-plugins ./pipelines/detect-secrets/plugins/ ./ --exclude-files ".*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints" --no-basic-auth-scan  --no-keyword-scan > .secrets.baseline
    else
        detect-secrets scan --plugin ./pipelines/detect-secrets/plugins/azuresas.py --plugin ./pipelines/detect-secrets/plugins/azuredatabrickstoken.py --plugin ./pipelines/detect-secrets/plugins/azurestoragekey.py  ./  --exclude-files ".*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints" --disable-plugin KeywordDetector --disable-plugin BasicAuthDetector --disable-filter  detect_secrets.filters.heuristic.is_prefixed_with_dollar_sign --disable-filter  detect_secrets.filters.heuristic.is_sequential_string  --disable-filter   detect_secrets.filters.heuristic.is_templated_secret > .secrets.baseline
    fi    
    git add .secrets.baseline
    git commit -m "adding secrets baseline"
fi

if [[ ! -f .pre-commit-config.yaml ]]; then
    echo "Updating .pre-commit-config.yaml"
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

    pre-commit install
    git add .pre-commit-config.yaml
    git commit -m "adding pre-commit config"
fi

echo "Checking if updated/added files contain secrets"
git checkout "$destBranchName"
git merge --no-commit --no-ff "$srcBranchName"

echo "Detect-secrets version: $(detect-secrets --version)"
echo "List of files to check:"
git diff --staged --name-only | grep -E -v -i '.*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints' 

# shellcheck disable=SC2071
if [[ $(detect-secrets --version) < 1 ]] ; then
   (git diff --staged --name-only | grep -E -v -i '.*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints' | xargs detect-secrets-hook --custom-plugins ./pipelines/detect-secrets/plugins/ --baseline .secrets.baseline)  || true 1> "$tmpFolder/detection.log" 2>&1 
else
    (git diff --staged --name-only | while read -r file; do echo "$repoRoot/$file" ; done | grep -E -v -i '.*/tests/.*|.secrets.baseline|\.env|__pycache__|\.vscode|\.pytest_cache|\.mypy_cache|\.git|^build|^dist|\.ipynb_checkpoints' | xargs detect-secrets-hook --plugin ./pipelines/detect-secrets/plugins/azuresas.py --plugin ./pipelines/detect-secrets/plugins/azuredatabrickstoken.py --plugin ./pipelines/detect-secrets/plugins/azurestoragekey.py  --baseline .secrets.baseline  --disable-plugin KeywordDetector --disable-plugin BasicAuthDetector --disable-filter  detect_secrets.filters.heuristic.is_prefixed_with_dollar_sign --disable-filter  detect_secrets.filters.heuristic.is_sequential_string  --disable-filter   detect_secrets.filters.heuristic.is_templated_secret)  || true 1> "$tmpFolder/detection.log" 2>&1    
fi

if [[ -f "$tmpFolder/detection.log" ]] ; then
    nbFound=$(grep -c "Potential secrets about to be committed to git repo!" "$tmpFolder/detection.log")
else
    echo "No Secret found"
    nbFound=0
fi
popd || exit

rm -rf "$tmpFolder"

if [[ "$nbFound" != "0" ]]; then
    echo "Potential secrets detected"
    exit 1
else
    echo "No secrets detected"
fi
