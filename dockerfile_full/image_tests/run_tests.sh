#!/bin/bash

# Get path where script file is stored
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Run image tests
if [ "${1}" == "standard" ] || [ "${1}" == "root" ]; then
    python3 "${BASE_DIR}/run_tests_${1}.py"
else
    printf "User privilege level \"%s\" is not valid. Please select " "${1}"
    printf "\"standard\" or \"root\"\n"
    exit 1
fi
