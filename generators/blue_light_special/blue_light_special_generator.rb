require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")
require File.expand_path(File.dirname(__FILE__) + "/lib/rake_commands.rb")

class BlueLightSpecialGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.directory File.join("config", "initializers")
      m.file "blue_light_special.rb",  "config/initializers/blue_light_special.rb"
      m.file "blue_light_special.yml", "config/blue_light_special.yml"

      m.insert_into "config/routes.rb",
                    "BlueLightSpecial::Routes.draw(map)"

      m.migration_template "migrations/#{migration_source_name}.rb",
                           'db/migrate',
                           :migration_file_name => "blue_light_special_#{migration_target_name}"
    end
  end

  def schema_version_constant
    if upgrading_blue_light_special_again?
      "To#{schema_version.gsub('_', '')}"
    end
  end

  private

  def migration_source_name
    if ActiveRecord::Base.connection.table_exists?(:users)
      'update_users'
    else
      'create_users'
    end
  end

  def migration_target_name
    if upgrading_blue_light_special_again?
      "update_users_to_#{schema_version}"
    else
      'create_users'
    end
  end

  def schema_version
    IO.read(File.join(File.dirname(__FILE__), '..', '..', 'VERSION')).strip.gsub(/[^\d]/, '_')
  end

  def upgrading_blue_light_special_again?
    ActiveRecord::Base.connection.table_exists?(:users)
  end

end
