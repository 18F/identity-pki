# -*- encoding: utf-8 -*-
# stub: subprocess 1.5.4 ruby lib

Gem::Specification.new do |s|
  s.name = "subprocess".freeze
  s.version = "1.5.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Carl Jackson".freeze, "Evan Broder".freeze, "Nelson Elhage".freeze, "Andy Brody".freeze, "Andreas Fuchs".freeze]
  s.date = "2021-01-13"
  s.description = "Control and communicate with spawned processes".freeze
  s.email = ["carl@stripe.com".freeze, "evan@stripe.com".freeze, "nelhage@stripe.com".freeze, "andy@stripe.com".freeze, "asf@stripe.com".freeze]
  s.homepage = "https://github.com/stripe/subprocess".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "A port of Python's subprocess module to Ruby".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<sord>.freeze, [">= 0"])
end
