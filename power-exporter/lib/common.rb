#!/bin/ruby

require 'yaml'
require 'logger'

require_relative 'config.rb'
require_relative 'nodes.rb'

require_relative 'ipmi.rb'
require_relative 'snmpv2.rb'
require_relative 'snmpv3.rb'
require_relative 'ipmi_ssh.rb'
require_relative 'fake.rb'

require_relative 'slurm.rb'
require_relative 'pbs.rb'
require_relative 'gridengine.rb'
require_relative 'openstack.rb'

$CONFIG=loadConfig()

$log = Logger.new($CONFIG['logging']['path'])
$log.level = Logger::INFO

$node_list = readNodeFile()
