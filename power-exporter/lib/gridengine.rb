#!/bin/ruby

require 'xmlsimple'

module GRIDENGINE
	def self.getNodes(schedulers)
	        nodes = {}

		schedulers.each do |scheduler, config|
                        qhost_bin = config.key?('qhost_bin') ? config['qhost_bin'] : "qhost"

			# Grab qhost xml output
                        if $CONFIG.key?('exporter') and $CONFIG['exporter'].key?('ssh_key') ; then
			  qhost_output = `ssh -o "StrictHostKeyChecking no" -i #{$CONFIG['exporter']['ssh_key']} #{scheduler} "#{qhost_bin} -j -xml" 2>/dev/null`
                        else
                          qhost_output = `ssh -o "StrictHostKeyChecking no" #{scheduler} "#{qhost_bin} -j -xml" 2>/dev/null`
                        end

			# Convert to xml
			begin
				qhost_xml = XmlSimple.xml_in(qhost_output)
			rescue
				$log.error "Failed to get gridengine qhost output from #{scheduler}"
				next
			end

			if not qhost_xml.key?('host') ; then
				$log.error "Failed to extract valid host(s) from #{scheduler}"
				next
			end

			qhost_xml['host'].each do |host|
				# Get the node short hostname
				node = host['name'].split(".")[0]
				state = "idle"

				# Check for duplicate hosts
				if nodes.key?(node) ; then
					$log.error "Duplicate node #{node} from #{scheduler}"
					next
				end

                        	# Check if the node has allocated jobs
                        	if host.key?('job') and host['job'].size > 0 ; then
					state = "allocated"
				end

				nodes[node] = { "state" => state }
			end
		end

		if nodes.empty? ; then
			return nil
		end

        	return nodes

	end
end
