#!/bin/ruby

def loadConfig()
        config_file_path = File.expand_path("#{File.expand_path(File.dirname(__FILE__))}/../etc/config.yaml")

        if not File.file?(config_file_path) ; then
                puts "Error - please configure #{config_file_path} first."
                exit 1
        end

        return YAML.load_file(config_file_path)
end
