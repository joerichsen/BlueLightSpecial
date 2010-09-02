require 'yaml'

begin
  configuration = YAML.load_file("#{Rails.root}/config/blue_light_special.yml")[Rails.env]
  configuration = HashWithIndifferentAccess.new(configuration)
  
  BlueLightSpecial.configure do |config|
    config.impersonation_hash   = configuration[:impersonation_hash]
  end
rescue LoadError
  puts "The /config/blue_light_special.yml file is missing or broken."
end
