# Detect secrets Pipeline 

## Overview

The pipeline (pipelines/check-for-secrets.yml) can be used to scan the secrets in the current repository.
This pipeline supports the following input variables:
- pythonVersion: the version of python to run detect-secrets (3.7 by default)
- inputPath: the path to be scanned
- excludeFiles: the regex value used to exclude files ('.*/tests/.*' by default all the files in tests folders)
- options: the additional options for detect-secrets ('--no-basic-auth-scan  --no-keyword-scan' by default)

Moreover, those input variables can be overloaded and defined in the Variable Group called 'check-secret-dev'.


## Check-for-secrets.yml pipeline 

This pipeline relies on detect-secrets tool available here: https://github.com/yelp/detect-secrets

When launched the pipeline will scan the repository to detect secrets.
Moreover, this pipeline does detect specific Azure secrets:
- Azure Storage Key
- Azure Storage Shared Access Signature Token
- Azure Databricks Token

The python plugins detecting Azure keys are stored under pipelines\scripts\plugins

The file pipelines\scripts\plugins\tests\tests.txt contains: 
- Azure Storage Key
- Azure Storage Shared Access Signature Token
- Azure Databricks Token

This file can be used to check whether the pipeline is correctly functionning.

If the pipeline detects secrets it will fail.
If the pipeline doesn't detect secret in the repository, it will succeed.

The source code of the pipeline can be found here:
[devops_pipelines/azure-pipelines.scan-secrets.yml](../../../devops_pipelines/azure-pipelines.scan-secrets.yml)


