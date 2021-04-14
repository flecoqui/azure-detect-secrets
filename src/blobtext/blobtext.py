
# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------
import io
import os
import random
import time
import uuid

from azure.storage.blob import BlobBlock, BlobServiceClient, ContentSettings
from azure.storage.common import CloudStorageAccount


class BlobText():
    def __init__(self, account_name, account_key, sas_token, container_name):
        self.account_name = account_name
        self.account_key = account_key
        self.sas_token = sas_token
        self.container_name = container_name

        # Create the BlobServiceClient object which will be used to create a container client
        self.blob_service_client = BlobServiceClient(
            "https://" + account_name + ".blob.core.windows.net/", account_key)

        # Create the container
        self.container_client = self.blob_service_client.get_container_client(
            container_name)
        if self.container_client is None:
            self.container_client = self.blob_service_client.create_container(
                container_name)

    def write_text(self,  blob_name, text):
        data = text.encode('utf-16')
        blobClient = self.container_client.get_blob_client(blob_name)
        if blobClient.exists:
            blobClient.delete_blob
        blobClient.upload_blob(data, overwrite=True)

    def read_text(self,  blob_name):
        blobClient = self.container_client.get_blob_client(blob_name)
        if blobClient.exists:
            data = blobClient.download_blob().readall()
            return data.decode('utf-16')
        else:
            return None
