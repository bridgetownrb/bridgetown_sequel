# frozen_string_literal: true

require "bridgetown"

# Needs export OBJC_DISABLE_INITIALIZE_FORK_SAFETY="yes" on macOS
# See: https://stackoverflow.com/questions/52671926/rails-may-have-been-in-progress-in-another-thread-when-fork-was-called
require "sequel"

module Bridgetown
  module Sequel
    def self.load_tasks(models_dir: "models")
      ENV["BRIDGETOWN_SEQUEL_MODELS_DIR"] ||= models_dir
      load File.expand_path("tasks/sequel_database.rake", __dir__)
    end
  end
end

Bridgetown.initializer :bridgetown_sequel do |
  config,
  models_dir: ENV.fetch("BRIDGETOWN_SEQUEL_MODELS_DIR", "models"),
  skip_autoload: false,
  model_setup: -> {},
  connection_options: {}
|
  unless skip_autoload
    config.autoload_paths << {
      path: models_dir,
      eager: true,
    }
  end

  config.database_models_dir = models_dir

  # Add a `Bridgetown.database` convenience method
  Bridgetown.define_singleton_method :database do
    Sequel::DATABASES.first
  end
  Bridgetown.singleton_class.alias_method :db, :database

  # Connect to the Database
  config.database_connection_options = connection_options
  # Example URI: postgres://user:password@localhost/blog
  Sequel.connect(config.database_uri, **connection_options)

  # Set up model plugins
  Sequel::Model.plugin :timestamps
  model_setup.(Sequel::Model)
end
