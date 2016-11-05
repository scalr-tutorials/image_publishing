#!/usr/bin/env bats

@test "apache2 binary is found in PATH" {
  run which apache2
  [ "$status" -eq 0 ]
}

@test "a2ensite command available" {
  run which a2ensite
  [ "$status" -eq 0 ]
}

