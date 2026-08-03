# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "bridgetown", ENV["BRIDGETOWN_VERSION"] if ENV["BRIDGETOWN_VERSION"]

group :test do
  gem "minitest", "< 6"
  gem "minitest-profile"
  gem "minitest-reporters"
end
