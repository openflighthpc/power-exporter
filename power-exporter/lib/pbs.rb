#!/bin/ruby

module PBS
	def self.getNodes(schedulers)
                nodes = {}

                schedulers.each do |scheduler, config|
                        pbsnodes_bin = config.key?('pbsnodes_bin') ? config['pbsnodes_bin'] : "pbsnodes"

			pbs_output = `pdsh -N -w #{scheduler} "#{pbsnodes_bin} -aSj -F json" 2>/dev/null`

			# Convert to JSON
			begin
				pbs_json = JSON.parse(pbs_output)
			rescue
				$log.error "Failed to get pbsnodes output from #{scheduler}"
				next
			end

			if not pbs_json.key?('nodes') ; then
				$log.error "Failed to extract valid host(s) from PBS scheduler #{scheduler}"
				next
			end

			pbs_json['nodes'].each do |name, details|
				node = name
				state = "idle"

				if details.key?('jobs') and details['jobs'].size > 0 ; then
					state = "allocated"
				end

				# Check for duplicate hosts
                                if nodes.key?(node) ; then
                                        $log.error "Duplicate node #{node} from #{scheduler}"
                                        next
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
