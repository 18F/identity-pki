#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

git rev-parse HEAD > REVISION.txt

if [ -d "vendor/bundle/ruby/3.2.0/" ];then
	echo "Lambda bundle has already been built."
	echo "Skipping rebuild."
	exit 0
fi

current_ruby_version=$(ruby -e 'puts RUBY_VERSION')

expected_ruby_version=$(cat .ruby-version)

root_directory="$(git rev-parse --show-toplevel)"

lambda_directory="$root_directory/terraform/app/lambda/kms_lambda_processors"

if [ "$current_ruby_version" != "$expected_ruby_version" ];then
	echo "ERROR: unexpected ruby version being used to build project."
	echo ""
	echo "Please cd into $lambda_directory and run ./scripts/install-deps.sh with ruby-3.2.2."
	exit 1
fi

rm -rf "$lambda_directory/vendor/bundle"
rm "$lambda_directory.zip"

gem install bundler -v '~> 2.3.18'

bundle install --deployment --without=development --jobs=4 --retry=3 --path "vendor/bundle" --gemfile "$lambda_directory/Gemfile"

# show resulting bundler config values
bundle config
