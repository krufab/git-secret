#!/usr/bin/env bats

load _test_base

FILE_TO_HIDE="$TEST_DEFAULT_FILENAME"
FILE_CONTENTS="hidden content юникод"
FILE_CONTENTS_UPDATED="hidden content юникод\na_new_line"
FILE_CONTENTS_CONFLICTS="hidden content юникод\n<<<<<<< file-on-disk\na_new_line\n=======\n>>>>>>> content-from-secret"

FINGERPRINT=""


function setup {
  FINGERPRINT=$(install_fixture_full_key "$TEST_DEFAULT_USER")

  set_state_initial
  set_state_git
  set_state_secret_init
  set_state_secret_tell "$TEST_DEFAULT_USER"
  set_state_secret_add "$FILE_TO_HIDE" "$FILE_CONTENTS"
  set_state_secret_hide
}


function teardown {
  rm "$FILE_TO_HIDE"

  uninstall_fixture_full_key "$TEST_DEFAULT_USER" "$FINGERPRINT"
  unset_current_state
}


@test "run 'reveal' with password argument" {
  cp "$FILE_TO_HIDE" "${FILE_TO_HIDE}2"
  rm -f "$FILE_TO_HIDE"

  local password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret reveal -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ -f "$FILE_TO_HIDE" ]

  cmp -s "$FILE_TO_HIDE" "${FILE_TO_HIDE}2"

  rm "${FILE_TO_HIDE}2"
}


@test "run 'reveal' with '-f'" {
  rm "$FILE_TO_HIDE"

  local password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret reveal -f -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ -f "$FILE_TO_HIDE" ]
}


@test "run 'reveal' with '-P'" {
  rm "$FILE_TO_HIDE"

  local password=$(test_user_password "$TEST_DEFAULT_USER")

  local secret_file=$(_get_encrypted_filename "$FILE_TO_HIDE")
  chmod o-rwx "$secret_file"

  run git secret reveal -P -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]

  local secret_perm
  local file_perm
  secret_perm=$(ls -l "$FILE_TO_HIDE$SECRETS_EXTENSION" | cut -d' ' -f1)
  file_perm=$(ls -l "$FILE_TO_HIDE" | cut -d' ' -f1)

  # text prefixed with '# ' and sent to file descriptor 3 is 'diagnostic' (debug) output for devs
  #echo "# secret_perm: $secret_perm, file_perm: $file_perm" >&3

  [ "$secret_perm" = "$file_perm" ]

  [ -f "$FILE_TO_HIDE" ]
}

@test "run 'reveal' with wrong password" {
  rm "$FILE_TO_HIDE"

  run git secret reveal -d "$TEST_GPG_HOMEDIR" -p "WRONG"
  [ "$status" -eq 2 ]
  [ ! -f "$FILE_TO_HIDE" ]
}


@test "run 'reveal' for attacker" {
  # Preparations
  rm "$FILE_TO_HIDE"

  local attacker_fingerprint=$(install_fixture_full_key "$TEST_ATTACKER_USER")
  local password=$(test_user_password "$TEST_ATTACKER_USER")

  run git secret reveal -d "$TEST_GPG_HOMEDIR" -p "$password"

  # This should fail, nothing should be created:
  [ "$status" -eq 2 ]
  [ ! -f "$FILE_TO_HIDE" ]

  # Cleaning up:
  uninstall_fixture_full_key "$TEST_ATTACKER_USER" "$attacker_fingerprint"
}

@test "run 'reveal' for attacker with -F (force)" {
  # Preparations
  rm "$FILE_TO_HIDE"

  local attacker_fingerprint=$(install_fixture_full_key "$TEST_ATTACKER_USER")
  local password=$(test_user_password "$TEST_ATTACKER_USER")

  run git secret reveal -F -d "$TEST_GPG_HOMEDIR" -p "$password"

  #echo "# status is $status" >&3

  # This should return a status code of 1 also.  Not sure how to test that we don't die early
  [ "$status" -eq 0 ]
  [ ! -f "$FILE_TO_HIDE" ]


  touch "$FILE_TO_HIDE"  #create this file so uninstall below works

  # Cleaning up:
  uninstall_fixture_full_key "$TEST_ATTACKER_USER" "$attacker_fingerprint"
}

@test "run 'reveal' for multiple users (with key deletion)" {
  # Preparations:
  local second_fingerprint=$(install_fixture_full_key "$TEST_SECOND_USER")
  local password=$(test_user_password "$TEST_SECOND_USER")
  set_state_secret_tell "$TEST_SECOND_USER"
  set_state_secret_hide

  # We are removing a secret key of the first user to be sure
  # that it is not used in decryption:
  uninstall_fixture_full_key "$TEST_DEFAULT_USER" "$FINGERPRINT"

  # Testing:
  run git secret reveal -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ -f "$FILE_TO_HIDE" ]

  # Cleaning up:
  uninstall_fixture_full_key "$TEST_SECOND_USER" "$second_fingerprint"
}


@test "run 'reveal' for multiple users (normally)" {
  # Preparations:
  local second_fingerprint=$(install_fixture_full_key "$TEST_SECOND_USER")
  # bug in gpg v2.0.22, need to use default password
  local password=$(test_user_password "$TEST_DEFAULT_USER")
  set_state_secret_tell "$TEST_SECOND_USER"
  set_state_secret_hide

  # Testing:
  run git secret reveal -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ -f "$FILE_TO_HIDE" ]

  # Cleaning up:
  uninstall_fixture_full_key "$TEST_SECOND_USER" "$second_fingerprint"
}

@test "run 'reveal' with '-s' and no local file" {
  rm -f "$FILE_TO_HIDE"

  local password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret reveal -s -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ -f "$FILE_TO_HIDE" ]

  cmp -s "$FILE_TO_HIDE" <(echo "$FILE_CONTENTS")
}


@test "run 'reveal' with '-s' and local file with same content" {
  local password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret reveal -s -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ -f "$FILE_TO_HIDE" ]

  cmp -s "$FILE_TO_HIDE" <(echo "$FILE_CONTENTS")
}


@test "run 'reveal' with '-s' and local file with different content" {
  echo -en "${FILE_CONTENTS_UPDATED}" > "$FILE_TO_HIDE"

  local password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret reveal -s -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ "$output" = "done. 1 of 1 files are revealed (1 merged)." ]
  [ -f "$FILE_TO_HIDE" ]

  cmp "$FILE_TO_HIDE" <(echo -e "$FILE_CONTENTS_CONFLICTS")
}


@test "run 'reveal' with '-s' twice and local file with same content" {
  local password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret reveal -s -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ "$output" = "done. 1 of 1 files are revealed (0 merged)." ]
  [ -f "$FILE_TO_HIDE" ]

  cmp "$FILE_TO_HIDE" <(echo "$FILE_CONTENTS")

  run git secret reveal -s -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ "$output" = "done. 1 of 1 files are revealed (0 merged)." ]
  [ -f "$FILE_TO_HIDE" ]

  cmp "$FILE_TO_HIDE" <(echo "$FILE_CONTENTS")
}


@test "run 'reveal' with '-s' twice and local file with different content" {
  echo -en "${FILE_CONTENTS_UPDATED}" > "$FILE_TO_HIDE"

  local password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret reveal -s -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -eq 0 ]
  [ "$output" = "done. 1 of 1 files are revealed (1 merged)." ]
  [ -f "$FILE_TO_HIDE" ]

  cmp "$FILE_TO_HIDE" <(echo -e "$FILE_CONTENTS_CONFLICTS")

  run git secret reveal -s -d "$TEST_GPG_HOMEDIR" -p "$password"

  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Conflicts were found in the following file(s):" ]
  [[ "${lines[1]}" == *"$FILE_TO_HIDE"* ]]
  [ "${lines[2]}" = "Resolve conflicts before continuing. Aborting." ]
  [ -f "$FILE_TO_HIDE" ]

  cmp "$FILE_TO_HIDE" <(echo -e "$FILE_CONTENTS_CONFLICTS")
}
