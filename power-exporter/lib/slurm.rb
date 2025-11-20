#!/bin/ruby

require 'json'

module SLURM

	ALLOCATED_STATES=["allocated", "completing", "draining", "mixed", "failing"]

	def self.getNodes(schedulers)
		nodes = {}

		schedulers.each do |scheduler, config|
			sinfo_bin = config.key?('sinfo_bin') ? config['sinfo_bin'] : "/usr/bin/sinfo"

			# Grab all of the current node states
                        if $CONFIG.key?('exporter') and $CONFIG['exporter'].key?('ssh_key') ; then
                          sinfo_output = `ssh -o "StrictHostKeyChecking no" -i #{$CONFIG['exporter']['ssh_key']} #{scheduler} "#{sinfo_bin} -N -O NODELIST,StateLong -h | sort | uniq" 2>/dev/null`
                        else
    			  sinfo_output = `ssh -o "StrictHostKeyChecking no" #{scheduler} "#{sinfo_bin} -N -O NODELIST,StateLong -h | sort | uniq" 2>/dev/null`
                        end

			if sinfo_output == "" ; then
				$log.error "Failed to get slurm sinfo output from #{scheduler}"
			else
				sinfo_output.each_line do |line|
					node = line.split[0]
                                        state = line.split[1].gsub!(/\W/,'')

					if ALLOCATED_STATES.include?(state) ; then
						state = "allocated"
					else
						state = "idle"
					end

					if nodes.key?(node) ; then
						$log.error "Duplicate node #{node} from #{scheduler}"
						next
					end

					nodes[node] = { "state" => state }
				end
			end
		end

		if nodes.empty? ; then
			return nil
		end

		return nodes
	end
end
