# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

"""
This plugin searches for Azure Databricks Token
"""
import re

from detect_secrets.plugins.base import RegexBasedDetector


class AzureDatabricksTokenDetector(RegexBasedDetector):
    """Scans for Azure Databricks Token."""

    secret_type = "Azure Databricks Token"

    denylist = [
        re.compile(r"\b([0-9a-z]{36})\b"),
    ]
