#!/bin/sh

# Find our paths.
if [ -e /usr/local/rvm/rubies/default ]; then
  PASSENGER_ROOT=$(/usr/local/bin/rvm default exec passenger-config --root)
  RUBY_PATH=$(/usr/local/bin/rvm default exec which ruby)
else
  PASSENGER_ROOT=$(passenger-config --root)
  RUBY_PATH=$(which ruby)
fi

# Escape paths for passing into sed:
PASSENGER_ROOT=$(echo $PASSENGER_ROOT | sed -e 's/\([\/ ]\)/\\\1/g')
RUBY_PATH=$(echo $RUBY_PATH | sed -e 's/\([\/ ]\)/\\\1/g')

# Patch the config:
sed -e "s/##PASSENGER_ROOT##/${PASSENGER_ROOT}/g" -i $1
sed -e "s/##RUBY_PATH##/${RUBY_PATH}/g" -i $1
