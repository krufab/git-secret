#!/usr/bin/env bash

# `SECRET_PROJECT_ROOT` must be set before running the script.

set -e

TMP_DIR_WITH_SPACES='tempdir with spaces'

# Running all the bats-tests in a dir with spaces:
cd "${SECRET_PROJECT_ROOT}"; rm -rf "${TMP_DIR_WITH_SPACES}"; mkdir "${TMP_DIR_WITH_SPACES}"; cd "${TMP_DIR_WITH_SPACES}";

export SECRETS_DIR=.gitsecret-testdir

# bats expects diagnostic lines to be sent to fd 3, matching regex '^ #' (IE, like: `echo '# message here' >&3`)
# bats ... 3>&1 shows diagnostic output when errors occur.
bats "${SECRET_PROJECT_ROOT}/tests/" 3>&1

cd "${SECRET_PROJECT_ROOT}"; rm -rf "${TMP_DIR_WITH_SPACES}"
