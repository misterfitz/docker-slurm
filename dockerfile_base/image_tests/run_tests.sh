#!/bin/bash

## SETUP ---------------------------------------------------------------------
# Validate inputs
if [ "${1}" == "standard" ] || [ "${1}" == "root" ]; then
    printf "Running image tests for %s user\n\n" "${1}"
else
    printf "User privilege level \"%s\" is not valid. Please select " "${1}"
    printf "\"standard\" or \"root\"\n"
    exit 1
fi

# Counters for number of passed and failed tests
num_pass=0
num_fail=0

check_pkg_exists() {
    pkg=$1

    install_path=$(command -v "$pkg")
    if [ ! -z "${install_path}" ]; then
        echo "PASS: Found package $pkg: ${install_path}"
        num_pass=$((num_pass+1))
    else
        echo "FAIL: Unable to find package $pkg"
        num_fail=$((num_fail+1))
    fi
}

# Give Slurm enough time to initialize
sleep 2


## TESTS ---------------------------------------------------------------------
# Check operating system
# shellcheck source=/dev/null
os_id=$(. /etc/os-release && echo "$ID")
if [ "${os_id}" == "rocky" ]; then
    echo "PASS: Operating system: Rocky Linux"
    num_pass=$((num_pass+1))
else
    echo "FAIL: Operating system: ${os_id} != rocky"
    num_fail=$((num_fail+1))
fi

# Check time zone
timezone=America/New_York
current_tz=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')
if [ "${current_tz}" == "${timezone}" ]; then
    echo "PASS: Time zone: ${timezone}"
    num_pass=$((num_pass+1))
else
    echo "FAIL: Time zone: ${current_tz} != ${timezone}"
    num_fail=$((num_fail+1))
fi

# Check user identity
if [ "$1" == "root" ]; then
    if [ "$(id -u)" == "0" ]; then
        echo "PASS: User identity: $(whoami) id $(id -u)"
        num_pass=$((num_pass+1))
    else
        echo "FAIL: User identity, $(whoami) id $(id -u), is not root"
        num_fail=$((num_fail+1))
    fi
elif [ "$1" == "standard" ]; then
    if [ "$(id -u)" == "0" ]; then
        echo "FAIL: User identity, $(whoami) id $(id -u), is root"
        num_fail=$((num_fail+1))
    else
        echo "PASS: User identity: $(whoami) id $(id -u)"
        num_pass=$((num_pass+1))
    fi
else
    echo FAIL: Provided user privilege level "$1" is not valid
    num_fail=$((num_fail+1))
fi

# Check for installation of `sudo` package
if [ "$1" == "standard" ]; then
    check_pkg_exists sudo
fi

# Check for installation of `openssl` package
check_pkg_exists openssl

# Check for installation of `sbatch` package
check_pkg_exists sbatch

# Check for installation of `srun` package
check_pkg_exists srun

# Check for installation of `squeue` package
check_pkg_exists squeue

# Check for installation of `sinfo` package
check_pkg_exists sinfo

# Check for installation of `scontrol` package
check_pkg_exists scontrol

# Check for expected output when running jobs
srun_output=$(srun hostname)
if [ "${srun_output}" == "$(hostname)" ]; then
    printf "PASS: srun hostname -> %s\n" "${srun_output}"
    num_pass=$((num_pass+1))
else
    printf "FAIL: srun hostname -> %s != %s\n" "${srun_output}" "$(hostname)"
    num_fail=$((num_fail+1))
fi

srun_output=$(srun pwd)
if [ "${srun_output}" == "$(pwd)" ]; then
    printf "PASS: srun pwd -> %s\n" "${srun_output}"
    num_pass=$((num_pass+1))
else
    printf "FAIL: srun pwd -> %s != %s\n" "${srun_output}" "$(pwd)"
    num_fail=$((num_fail+1))
fi


## TEST RESULTS --------------------------------------------------------------
# Display results
total_tests=$((num_pass + num_fail))
printf "\n---------------------------------------------\n"
printf "Ran %s test(s)\n" "$total_tests"
printf "  %s test(s) passed\n" "$num_pass"
printf "  %s test(s) failed\n" "$num_fail"

# Return exit code 0 if all tests passed and 1 otherwise
if [ "$num_fail" -eq "0" ]; then
    exit 0
else
    exit 1
fi
