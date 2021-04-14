# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

""" This python code analyze the result of detect-secrets command """
import json
import os
import sys

""" This function is used to render binary character """


def strip_nonascii(b):
    return b.decode("ascii", errors="ignore")


""" This function is used to find a secret in a list of string """


def find_secret(sec, lines):
    if len(lines) > 0:
        for line in lines:
            try:
                if line.find(sec.strip()) >= 0:
                    return 1
            except Exception as e:
                print(f"Error for string at line {line}: Exception: {repr(e)}")
    return 0


""" Main program """


class bcolors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


ref_lines = []
lines = []
ref_secret_file_path = f"{sys.argv[0]}.txt"
if len(sys.argv) > 1:
    ref_secret_file_path = sys.argv[1]
    print(f"Reading secret reference file: {ref_secret_file_path}")
    try:
        f = open(ref_secret_file_path, "rb")
        lines = f.readlines()
    except OSError:
        print(f"Could not open/read the file containing the list of allowed secrets:{ref_secret_file_path}")

count = 0
if len(lines) > 0:
    for line in lines:
        line = strip_nonascii(line.rstrip())
        if (
            (line.find("File:") >= 0)
            and (line.find("Line:") >= 0)
            and (line.find("Secret Type:") >= 0)
        ):
            ref_lines.append(line)

if len(ref_lines) > 0:
    print(
        "List of allowed secrets:"
    )
    for line in ref_lines:
        count += 1
        print(f"Secret {count}: {line}")
else:
    print("The list of allowed secrets is empty")

counter = 0
for key, value in json.load(sys.stdin)["results"].items():
    for i in range(0, len(value), 1):
        secret = f"File: {key} - Line: {str(value[i]['line_number'])} - Secret Type: {value[i]['type']}"
        # check if the secret is accepted
        if find_secret(secret, ref_lines) == 0:
            if counter == 0:
                print(f"\n{bcolors.FAIL}SECRETS DETECTED IN THE CODE:{bcolors.ENDC}\n")
            print(f"{secret}")
            counter = counter + 1

if counter == 0:
    print("\nNO SECRET DETECTED!\n")
    sys.exit(os.EX_OK)
sys.exit(os.EX_DATAERR)
