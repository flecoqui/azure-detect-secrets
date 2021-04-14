# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

"""
This plugin searches for Azure SAS Access keys
"""
import re

from detect_secrets.plugins.base import RegexBasedDetector


class AzureSASTokenDetector(RegexBasedDetector):
    """Scans for Azure SAS Token."""

    secret_type = "Azure SAS Token"

    denylist = [
        re.compile(r"(?=.*sv=*)(?=.*&se=*)(?=.*&sig=[\%0-9a-zA-Z]{20})"),
    ]
