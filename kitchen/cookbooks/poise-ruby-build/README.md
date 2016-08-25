# Poise-Ruby-Build Cookbook

[![Build Status](https://img.shields.io/travis/poise/poise-ruby-build.svg)](https://travis-ci.org/poise/poise-ruby-build)
[![Gem Version](https://img.shields.io/gem/v/poise-ruby-build.svg)](https://rubygems.org/gems/poise-ruby-build)
[![Cookbook Version](https://img.shields.io/cookbook/v/poise-ruby-build.svg)](https://supermarket.chef.io/cookbooks/poise-ruby-build)
[![Coverage](https://img.shields.io/codecov/c/github/poise/poise-ruby-build.svg)](https://codecov.io/github/poise/poise-ruby-build)
[![Gemnasium](https://img.shields.io/gemnasium/poise/poise-ruby-build.svg)](https://gemnasium.com/poise/poise-ruby-build)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A [ruby-build](https://github.com/sstephenson/ruby-build) provider for the
[poise-ruby cookbook](https://github.com/poise/poise-ruby).

## Provider

The `ruby_build` provider uses [ruby-build](https://github.com/sstephenson/ruby-build)
to compile and install Ruby.

```ruby
ruby_runtime 'myapp' do
  provider :ruby_build
  version '2.1'
end
```

### Options

* `install_doc` – Install documentation with Ruby. *(default: false)*
* `install_repo` – Git URI to clone to install ruby-build. *(default: https://github.com/sstephenson/ruby-build.git)*
* `install_rev` – Git revision to clone to install ruby-build. *(default: master)*
* `prefix` – Base path for install ruby-build and rubies. *(default: /opt/ruby_build)*
* `version` – Override the Ruby version.

## Sponsors

Development sponsored by [Bloomberg](http://www.bloomberg.com/company/technology/).

The Poise test server infrastructure is sponsored by [Rackspace](https://rackspace.com/).

## License

Copyright 2015-2016, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
