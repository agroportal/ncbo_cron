source 'https://rubygems.org'

gemspec


# This is needed temporarily to pull the Google Universal Analytics (UA)
# data and store it in a file. See (bin/import_google_ua_analytics_data)
# The ability to pull this data from Google will cease on July 1, 2024
gem "google-apis-analytics_v3"
gem 'google-analytics-data', '0.6.0'
gem 'google-protobuf', '3.25.3'
gem 'grpc', '1.70.1'
gem 'mail', '2.6.6'
gem 'multi_json'
gem 'oj'
gem 'parseconfig'
gem 'pony'
gem 'pry'
gem 'rake'
gem 'redis'
gem 'rest-client'
gem 'sys-proctable'
gem 'request_store'
gem 'parallel'
gem 'json-ld'
gem 'ffi', '1.15.0'
gem 'activesupport', '~> 5.0'
gem 'rackup'


gem 'goo', github: 'agroportal/goo', branch: 'development'
gem 'ontologies_linked_data', github: 'agroportal/ontologies_linked_data', branch: 'development'
gem 'sparql-client', github: 'agroportal/sparql-client', branch: 'development'
gem 'ncbo_annotator', github: 'agroportal/ncbo_annotator', branch: 'development'

# Testing
group :test do
  gem 'email_spec'
  gem 'minitest'
  gem 'simplecov'
  gem 'simplecov-cobertura' # for codecov.io
  # gem 'test-unit-minitest'
  gem 'crack', '0.4.5'
  gem 'webmock'
  gem "minitest-hooks", "~> 1.5"
  gem 'webrick'
end

group :development do
  # bcrypt_pbkdf and ed35519 is required for capistrano deployments when using ed25519 keys; see https://github.com/miloserdow/capistrano-deploy/issues/42
  gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0', require: false
  gem 'capistrano', '~> 3', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-locally', require: false
  gem 'capistrano-rbenv', require: false
  gem 'ed25519', '>= 1.2', '< 2.0', require: false
end

gem 'cube-ruby'
gem "binding_of_caller", "~> 1.0"
gem 'concurrent-ruby', '1.3.4'
gem 'net-smtp'
gem 'net-ftp'
gem 'rubyzip', '= 2.4.1'
