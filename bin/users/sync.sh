#!/bin/bash

cd $(dirname $0)

go run sync.go "$@"
