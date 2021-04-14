# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------
from setuptools import find_packages, setup

package_name = "blobtext"
base_version = "0.1.0"
requirements_file_name = ".devcontainer/requirements_blobtext.txt"

# read required packages 
with open(requirements_file_name) as f:
    required_packages = f.read().splitlines()
# filter "", " ", "#"
required_packages = [
    package.strip(" ")
    for package in required_packages
    if package.strip(" ") and "#" not in package
]

setup(
    name=package_name,
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    version=base_version,
    description="A short description of the project.",
    author="Contoso",
    license="",
    python_requires="~=3.8",
    install_requires=required_packages,
)

