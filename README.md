# Bridgetown Sequel

A Bridgetown plugin to make it easy to integrate and use [Sequel](https://sequel.jeremyevans.net), a popular database toolkit for Ruby.

It's been tested only with PostgreSQL, but it should support any of the databases supported by Sequel.

## Installation

Run these commands to add this plugin along with the database adapter of your choice to your site's Gemfile:

```shell
bundle add pg # or sqlite3, etc.
bundle add bridgetown_sequel
```

Then add the database URI and initializer to your configuration in `config/initializers.rb` (note that the initializer _must_ be excepted from the `sequel_tasks` context):

```ruby
database_uri ENV.fetch("DATABASE_URL", "postgres://localhost/your_database_name_here_#{Bridgetown.env}")

except :sequel_tasks do
  init :bridgetown_sequel
end
```

You'll also want to add this plugin's Rake tasks to your `Rakefile`:

```rb
# This is at the top of your Rakefile already:
Bridgetown.load_tasks

# Now add this:
require "bridgetown_sequel"
BridgetownSequel.load_tasks
```

Finally, you'll want to create a `models` folder at the top-level of your site repo, as well as a `migrations` folder.

### Resolving PostgreSQL fork error on macOS

There's a bug on macOS which will crash Bridgetown & Sequel unless you disable PostgreSQL's GSSAPI support (not needed for local development). You'll need to update your configuration as follows:

```rb
init :bridgetown_sequel do
  connection_options do
    if RUBY_PLATFORM.include?("darwin")
      driver_options { gssencmode "disable" }
    end
  end
end
```

### Ensuring Puma forks successfully in production

In production, Bridgetown's Puma server configuration is set to "clustered mode" which forks the server process several times. This will result in Sequel connection errors if you don't shut down the database connection first. Update your `config/puma.rb` file so the production config looks like this:

```rb
if ENV["BRIDGETOWN_ENV"] == "production"
  workers ENV.fetch("BRIDGETOWN_CONCURRENCY") { 4 }
  before_fork do
    Bridgetown.db.disconnect if defined?(Bridgetown) && Bridgetown.respond_to?(:db)
  end
end
```

## Usage

To add your first database table & model, first you'll want to add a model file to your new `models` folder. It can look as simple as this:

```rb
# models/project.rb

class Project < Sequel::Model
  # you can add optional model configuration along with your own Ruby code here later...
end
```

Next, you'll want to create a migration. Run the following command:

```shell
bin/bridgetown db::migrations:new filename=create_projects
```

And modify the new `migrations/001_create_projects.rb` file to look something like this:

```rb
Sequel.migration do
  change do
    create_table(:projects) do
      primary_key :id
      String :name, null: false
      String :category
      Integer :order, default: 0

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
```

Now let's set up the database and run migrations. First, run this command (you only need to do this once for your repo):

```shell
bin/bridgetown db:setup
```

Then run migrations:

```shell
bin/bridgetown db:migrate
```

This will create the `projects` table and annotate your `models/project.rb` file with comments showing the table schema.

Now let's test your model. Run `bin/bridgetown console` (or `bin/bt c` for short):

```rb
> Project.create(name: "My new project")

> project = Project[1]
```

You should now see that you can save and load project records in your database.

If you ever need to drop your database and start over, run `bin/bridgetown db:drop`.

### Optional Configuration

You can pass various options to the `bridgetown_sequel` initializer to customize the behavior of Sequel:

```rb
init :bridgetown_sequel do
  connection_options do # pass options to Sequel's `connect` method
    # This adds a nice console debugging feature, aka `Project.dataset.print`
    extensions [:pretty_table]
  end
  skip_autoload true # only set to `true` if you're manually configuring your autoload settings
  models_dir "another_folder" # change the default `models` to something else
  model_setup ->(model) do # here you can add `Sequel::Model` plugins to apply to all your models
    model.plugin :update_or_create 
  end
end
```

At any time after the initializer is run, you can access `Bridgetown.database` (aliased `db`) anywhere in your Ruby code to access the Sequel connection object. (This is equivalent to the `DB` constant you see in a lot of Sequel documentation.) For example, in your console:

```rb
> db = Bridgetown.db
> db.fetch("SELECT * FROM projects ORDER BY name desc LIMIT 1").first
> db["SELECT COUNT(*) FROM projects"].first[:count]
```

Raw SQL statements won't be logged out-of-the-box, but you can attach Bridgetown's logger to Sequel. Just add this statement right after your initializer:

```rb
Bridgetown.db.loggers << Bridgetown.logger
```

For a quick reference on what you can do with the Sequel DSL, check out this [handy cheat sheet](https://devhints.io/sequel).

## Contributing

1. Fork it (https://github.com/bridgetownrb/bridgetown_sequel/fork)
2. Clone the fork using `git clone` to your local development machine.
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

## Testing

* Run `bundle exec rake test` to run the test suite
* Or run `script/cibuild` to validate with Rubocop and Minitest together.
