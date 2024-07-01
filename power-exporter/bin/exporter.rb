#!/bin/ruby

require 'net/http/server'

require_relative '../lib/common.rb'

def collectMetrics()
	metrics = []

	# Get slurm node states
	if $CONFIG.key?('scheduler') and $CONFIG['scheduler'].is_a?(Hash) ; then
		if $CONFIG['scheduler'].key?('slurm') and $CONFIG['scheduler']['slurm']['enabled'] ; then
			slurm_nodes = SLURM.getNodes($CONFIG['scheduler']['slurm']['schedulers'])
		end

		# Get gridengine node states
		if $CONFIG['scheduler'].key?('gridengine') and $CONFIG['scheduler']['gridengine']['enabled'] ; then
			gridengine_nodes = GRIDENGINE.getNodes($CONFIG['scheduler']['gridengine']['schedulers'])
		end

		# Get pbs node states
		if $CONFIG['scheduler'].key?('pbs') and $CONFIG['scheduler']['pbs']['enabled'] ; then
			pbs_nodes = PBS.getNodes($CONFIG['scheduler']['pbs']['schedulers'])
		end

		# Get Openstack hypervisor states
		if $CONFIG['scheduler'].key?('openstack') and $CONFIG['scheduler']['openstack']['enabled'] ; then
			clouds = OPENSTACK.getNodes($CONFIG['scheduler']['openstack']['clouds'])
 		end
	end

        if not $node_list ; then
                return []
        end


	$node_list.each do |node, node_config|
		state = nil
		power = 0.0

		if not node_config.key?('method') ; then
			$log.error "No power collection method configured for #{node}"
			next
		end

		if not $CONFIG['methods'].key?(node_config['method']) ; then
			$log.error "Error - unconfigured collection method #{node_config['method']} set for #{node}"
			next
		end

	        case node_config['method']
        	when "ipmi"
			if not $CONFIG['methods']['ipmi'].key?('user') or not $CONFIG['methods']['ipmi'].key?('password') ; then
				$log.error "Error - ipmi collection method not configured correctly."
				next
			end

                	ipmi_user = (node_config.key('ipmi') and node_config['ipmi'].key?('user')) ? node_config['ipmi']['user'] : $CONFIG['methods']['ipmi']['user']
	                ipmi_password = (node_config.key?('ipmi') and npde_config['ipmi'].key?('password')) ? node_config['ipmi']['password'] : $CONFIG['methods']['ipmi']['password']

        	        power = IPMI.getPower(node_config['host'], ipmi_user, ipmi_password, node_config['sensors'])

			if power.nil? ; then
				$log.error "Unable to get power usage for #{node} via method #{node_config['method']}"
				power = 0.0
			end
                when "ipmi_ssh"
                        power = IPMI_SSH.getPower(node_config['host'], node_config['sensors'])

                        if power.nil? ; then
                                $log.error "Unable to get power usage for #{node} via method #{node_config['method']}"
                                power = 0.0
                        end
	        when "snmpv2"
			if not $CONFIG['methods']['snmpv2'].key?('community') ; then
				$log.error "Error - snmpv2 collection method not configured correctly."
				next
			end

        	        snmp_community = (node_config.key?('snmpv2') and node_config['snmpv2'].key?('community')) ? node_config['snmpv2']['community'] : $CONFIG['methods']['snmpv2']['community']

	                power = SNMPv2.getPower(node_config['host'], snmp_community, node_config['oids'])

			if power.nil? ; then
                	        $log.error "Unable to get power usage for #{node} via method #{node_config['method']}"
                        	power = 0.0
	                end
		when "snmpv3"
			if not $CONFIG['methods']['snmpv3'].key?('username') ; then
				$log.error "Error - snmpv3 collection method not configured correctly."
				next
			end

			snmp_username = (node_config.key?('snmpv3') and node_config['snmpv3'].key?('username')) ? node_config['snmpv3']['username'] : $CONFIG['methods']['snmpv3']['username']

			power = SNMPv3.getPower(node_config['host'], snmp_username, node_config['oids'])

			if power.nil? ; then
				$log.error "Unable to get power usage for #{node} via method #{node_config['method']}"
				power = 0.0
			end
                when "fake"
                        if not $CONFIG['methods'].key?("fake") or not $CONFIG['methods']['fake'].key?("min") or not $CONFIG['methods']['fake'].key?("max") ; then
                                $log.error "Error - fake collection method not configured correctly."
                                next
                        end

                        min_power = (node_config.key?('fake') and node_config['fake'].key?('min') ? node_config['fake']['min'] : $CONFIG['methods']['fake']['min'])
                        max_power = (node_config.key?('fake') and node_config['fake'].key?('max') ? node_config['fake']['max'] : $CONFIG['methods']['fake']['max'])

                        power = FakePower.getPower(min_power, max_power)

                        if power.nil? ; then
                                $log.error "Unable to get power usage for #{node} via method #{node_config['method']}"
                                power = 0.0
                        end
        	else
                	$log.error "Unknown power collection method #{node_config['method']} for #{node}"
	                next
        	end

		case node_config['type']
		when "core"
			state = nil
		when "storage"
			state = nil
		when "login"
			state = nil
		when "compute"
			state = "idle"

			if not node_config.key?('scheduler') ; then
				$log.error "No scheduler configured for #{node}"
				state = nil
			elsif not $CONFIG['scheduler'].key?(node_config['scheduler']) ; then
				$log.error "Unknown scheduler #{node_config['scheduler']} configured for #{node}"
			elsif not $CONFIG['scheduler'][node_config['scheduler']]['enabled'] ; then
				$log.error "Disabled scheduler #{node_config['scheduler']} configured for #{node}"
			else
				case node_config['scheduler']
                                when "noop"
                                        if node_config.key?('state') and (node_config['state'] == "idle" or node_config['state'] == "allocated") ; then
                                                state = node_config['state']
                                        else
                                                state = nil
                                        end
				when "slurm"
					if slurm_nodes.nil? or not slurm_nodes.key?(node) ; then
						$log.error "Unable to determine state of #{node}"
					else
						state = slurm_nodes[node]['state']
					end
				when "gridengine"
					if gridengine_nodes.nil? or not gridengine_nodes.key?(node) ; then
						$log.error "Unable to determine state of #{node}"
					else
						state = gridengine_nodes[node]['state']
					end
				when "pbs"
					if pbs_nodes.nil? or not pbs_nodes.key?(node) ; then
						$log.error "Unable to determine state of #{node}"
					else
						state = pbs_nodes[node]['state']
					end
				when "openstack"
                                        if not node_config.key?('cloud') or not clouds.key?(node_config['cloud']) or clouds[node_config['cloud']].nil? or not clouds[node_config['cloud']].key?(node) ; then
                                                $log.error "Unable to determine state of #{node}"
                                        else
                                                state = clouds[node_config['cloud']][node]
                                        end
				end
			end
		else
			$log.error "Unknown type #{node_config['type']} configured for #{node}"
			state = nil
		end

		if state.nil? ; then
			metrics << "node_power_usage{node=\"#{node}\", type=\"#{node_config['type']}\", rack=\"#{node_config['rack']}\"} #{power}\n"
		else
			metrics << "node_power_usage{node=\"#{node}\", type=\"#{node_config['type']}\", rack=\"#{node_config['rack']}\", state=\"#{state}\"} #{power}\n"
		end
	end

	return metrics
end

def runServer()
	# Default port
	port = 9106

	# Override port from config if set
	if $CONFIG.key('exporter') and $CONFIG['exporter'].key?('port') ; then
		port = $CONFIG['exporter']['port']
	end

	$log.info "Starting power exporter on port #{port}.."

	Net::HTTP::Server.run(:port => port) do |request,stream|
		if request[:method] == "GET" and request[:uri][:path] == "/" ; then
			[200, {'Content-Type' => 'text/html'}, ['<html><head><title>Power Usage Exporter</title></head><body><h1>Power Usage Exporter</h1><p><a href="/metrics">Metrics</a></p></body></html>']]
		elsif request[:method] == "GET" and request[:uri][:path] == "/metrics"
			metrics = collectMetrics()
			[200, {'Content-Type' => 'text/html'}, [metrics.join('')]]
		else
			[404, {'Content-Type' => 'text/html'}, []]
		end
	end
end

runServer()
