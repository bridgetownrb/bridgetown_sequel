namespace :db do
  desc "Create the configured database"
  task :setup => :environment do
    run_initializers context: :sequel_tasks
    database_name = File.basename(site.config.database_uri)
    sh "createdb #{database_name}"

    automation do
      say_status :database, "Database created."
    end
  rescue RuntimeError
    nil
  end

  desc "Drop the configured database"
  task :drop => :environment do
    run_initializers context: :sequel_tasks
    answer = nil
    automation do
      answer = ask "Are you sure you want to drop the database? Type Y to continue, N to cancel:"
    end
    next unless answer.casecmp?("y")

    database_name = File.basename(site.config.database_uri)
    sh "dropdb #{database_name}"

    automation do
      say_status :database, "Database dropped."
    end
  rescue RuntimeError
    nil
  end

  desc "Run database migrations"
  task :migrate, [:version] => :environment do |_t, args|
    run_initializers context: :sequel_tasks

    require "sequel"
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]

    options = site.config.database_connection_options || {}
    Sequel.connect(site.config.database_uri, logger: Logger.new($stderr), **options) do |db|
      Sequel::Migrator.run(db, "migrations", target: version)
    end

    puts
    automation do
      say_status :database, "Migration complete."
    end

    Bundler.original_system "bin/bridgetown db:annotate"
  end

  namespace :migrations do
    desc "Create a new migration file with the specified name"
    task :new, [:filename] => :environment do |t, args|
      run_initializers context: :sequel_tasks

      # thanks to standalone-migrations gem for inspiration here
      name = args[:filename] || ENV.fetch("filename", nil)
      # options = args[:options] || ENV['options'] # TODO

      unless name
        automation do
          say_status :database, "You must provide a migration name to generate.", :red
          say_status :database,
                     "For example: bin/bridgetown #{t.name} filename=add_fields_to_model",
                     :red
        end
        abort
      end

      require "sequel"
      Sequel.extension :migration
      options = site.config.database_migration_connection_options || {}
      Sequel.connect(site.config.database_uri, logger: Logger.new($stderr), **options) do |db|
        current_version = begin
          migrator = Sequel::IntegerMigrator.new(db, "migrations")
          migrator.send(:latest_migration_version)
        rescue Sequel::Migrator::Error
          0
        end
        new_version = (current_version + 1).to_s.rjust(3, "0")
        automation do
          create_file "migrations/#{new_version}_#{name}.rb", <<~RUBY
            Sequel.migration do
              change do
                create_table(:table_name_here) do
                  primary_key :id
                  DateTime :created_at
                  DateTime :updated_at

                  # add your schema here
                end
              end
            end
          RUBY
          say_status :database, "Migration created."
        end
      end
    end
  end

  desc "Update model annotations"
  task :annotate => :environment do
    run_initializers context: :rake
    models = Dir["#{site.config.database_models_dir}/*.rb"]

    require "sequel/annotate"
    Sequel::Annotate.annotate(models, border: true)

    automation do
      models.each { say_status :database, "Annotated #{_1}" }
    end
  rescue Sequel::DatabaseError
    say_status :database, "Annotations failed. Perhaps you performed a rollback?", :red
  end
end
