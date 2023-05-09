#!/bin/sh
set -eux
cd "$(dirname "$0")/.."

if [ -d "vendor/bundle/ruby/2.7.0/" ];then
	echo "Lambda bundle has already been built."
	echo "Skipping rebuild."
	exit 0
fi

current_ruby_version=$(ruby -e 'puts RUBY_VERSION')

expected_ruby_version=$(cat .ruby-version)

if [ "$current_ruby_version" != "$expected_ruby_version" ];then
	echo "ERROR: unexpected ruby version being used to build project."
	exit 1
fi

gem install bundler -v '~> 2.1.4'

git rev-parse HEAD > REVISION.txt

root_directory="$(git rev-parse --show-toplevel)"

lambda_directory="$root_directory/terraform/app/lambda/kms_lambda_processors"

bundle install --deployment --without=development --jobs=4 --retry=3 --path "vendor/bundle" --gemfile "$lambda_directory/Gemfile"

# show resulting bundler config values
bundle config
