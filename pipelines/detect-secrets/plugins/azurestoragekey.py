# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

"""
This plugin searches for Azure Storage Access keys
"""

import re

from detect_secrets.plugins.base import RegexBasedDetector


class AzureDataLakeStorageKeyDetector(RegexBasedDetector):
    """Scans for Azure Data Lake Storage Access keys."""

    secret_type = "Azure Data Lake Storage Access Key"

    denylist = [
        re.compile(r"\b([\/\+0-9a-zA-Z]{86})\b=="),
    ]
