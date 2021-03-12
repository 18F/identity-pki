#!/bin/sh
#
# This script sets up the environment variables so that terraform and
# the tests can know how to run and what to test.
#

export REGION="us-west-2"

go test -v -timeout 60m
