#!/bin/ruby

def readNodeFile()
        node_file_path = File.expand_path("#{File.expand_path(File.dirname(__FILE__))}/../etc/nodes.yaml")

        if not File.file?(node_file_path) ; then
                puts "Error - please configure #{node_file_path} first."
                exit 1
        end

        return YAML.load_file(node_file_path)
end
