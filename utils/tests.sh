#!/usr/bin/env bash

# `SECRET_PROJECT_ROOT` must be set before running the script.

set -e

TMP_DIR_WITH_SPACES='tempdir with spaces'

# Running all the bats-tests in a dir with spaces:
cd "${SECRET_PROJECT_ROOT}"; rm -rf "${TMP_DIR_WITH_SPACES}"; mkdir "${TMP_DIR_WITH_SPACES}"; cd "${TMP_DIR_WITH_SPACES}";

# test with non-standard SECRETS_DIR (normally .gitsecret) and SECRETS_EXTENSION (normally .secret)
export SECRETS_DIR=.gitsecret-testdir
export SECRETS_EXTENSION=.secret2
#export SECRETS_VERBOSE=''

# bats expects diagnostic lines to be sent to fd 3, matching regex '^ #' (IE, like: `echo '# message here' >&3`)
# bats ... 3>&1 shows diagnostic output when errors occur.
bats "${SECRET_PROJECT_ROOT}/tests/" 3>&1

cd "${SECRET_PROJECT_ROOT}"; rm -rf "${TMP_DIR_WITH_SPACES}"
