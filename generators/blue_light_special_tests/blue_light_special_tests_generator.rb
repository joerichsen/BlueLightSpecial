class BlueLightSpecialTestsGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.directory File.join("test", "integration")

      ["test/integration/impersonation_test.rb"].each do |file|
        m.file file, file
       end
      
      m.readme "README"
    end
  end

end
