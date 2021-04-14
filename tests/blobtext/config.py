"""This module covers unit tests configuration."""
# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------
# fake storage account name and keys
STORAGE_ACCOUNT_NAME='blobstorage'
STORAGE_ACCOUNT_KEY='ZXRMd1ntYdjJuGlths7xycy64Ul8ax8Povm3fqXlVq/5JB0j64D9fhgQmeUCLEbJfHlB5Y8QXm7OT+v4H8tTjw=='
STORAGE_CONTAINER_NAME='testblobtext'
STORAGE_BLOB_NAME='blobtext'
STORAGE_ACCOUNT_SAS_TOKEN='sp=rcw&st=2021-04-11T07:42:11Z&se=2022-05-01T15:42:11Z&spr=https&sv=2020-02-10&sr=c&sig=1dTjiJxwNo4hcTvykCr5kgdOUDNvfDPNCkMaIxHeu%2FM%3D'
def read_env_file(path: str) -> dict:
    """Return the dictionnary of env variables.

    Args:
        str: path of .env file which contains env variables

    Returns:
        dict[str, str]: Key Value dictionnary
    """    
    with open(path, 'r') as f:
       return dict(tuple(line.replace('\n', '').split('=',1)) for line
                in f.readlines() if not line.startswith('#'))

def get_value(list: dict, key: str) -> str:
    """Return the value of variables .

    Args:
        dict: dictionnary of env variables  
        str: key of the variable to read 

    Returns:
        str: Key Value 
    """        
    default_value = ''
    if key == "STORAGE_ACCOUNT_NAME":
        default_value = STORAGE_ACCOUNT_NAME
    if key == "STORAGE_ACCOUNT_KEY":
        default_value = STORAGE_ACCOUNT_KEY
    if key == "STORAGE_CONTAINER_NAME":
        default_value = STORAGE_CONTAINER_NAME
    if key == "STORAGE_BLOB_NAME":
        default_value = STORAGE_BLOB_NAME
    if key == "STORAGE_ACCOUNT_SAS_TOKEN":
        default_value = STORAGE_ACCOUNT_SAS_TOKEN
    return list.get(key,default_value)

