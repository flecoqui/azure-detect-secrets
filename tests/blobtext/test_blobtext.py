# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------
import os

import pytest

from blobtext.blobtext import BlobText


def test_write_blob_text():
    """Test write text in blob."""
    try:
        import config
    except:
        raise ValueError('Please specify configuration settings in config.py.')

    # Note that account key and sas should not both be included
    try:
        list = config.read_env_file(os.path.dirname(os.path.abspath(__file__))+"/.env")
        print(list)
        account_name = config.get_value(list,"STORAGE_ACCOUNT_NAME")
        account_key = config.get_value(list,"STORAGE_ACCOUNT_KEY")
        sas_token = config.get_value(list,"STORAGE_ACCOUNT_SAS_TOKEN")
        container_name = config.get_value(list,"STORAGE_CONTAINER_NAME") 
        blob_name = config.get_value(list,"STORAGE_BLOB_NAME") 
        blob = BlobText(account_name, account_key, sas_token, container_name)
        text = u"Hello"
        blob.write_text(blob_name, text)
        print('\nWrite into '+blob_name+' content: '+text)
    except Exception:
        assert False    

def test_read_blob_text():
    """Test read text in blob."""
    try:
        import config
    except:
        raise ValueError('Please specify configuration settings in config.py.')

    # Note that account key and sas should not both be included
    try:
        list = config.read_env_file(os.path.dirname(os.path.abspath(__file__))+"/.env")
        print(list)
        account_name = config.get_value(list,"STORAGE_ACCOUNT_NAME")
        account_key = config.get_value(list,"STORAGE_ACCOUNT_KEY")
        sas_token = config.get_value(list,"STORAGE_ACCOUNT_SAS_TOKEN")
        container_name = config.get_value(list,"STORAGE_CONTAINER_NAME") 
        blob_name = config.get_value(list,"STORAGE_BLOB_NAME") 
        blob = BlobText(account_name, account_key, sas_token, container_name )
        text = blob.read_text(blob_name)
        print('\nRead from '+blob_name+' content: '+text)
        if text != u"Hello":
            assert False    
    except Exception:
        assert False    

