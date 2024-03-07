#!/bin/ruby 

require 'json'
require 'net/http'

module OPENSTACK
        def self.getNodes(clouds)
		hypervisors = {}

		clouds.each do |cloud, config|
			token = getToken(config['username'], config['password'], config['keystone_endpoint'])

			# Skip trying to gather hypervisor states if we failed to get a token
			if token.nil?
				$log.error "Failed to get valid Openstack token."
				hypervisors[cloud] = nil
				next
			end

			hypervisors[cloud] = getHypervisorStates(token, config['nova_endpoint'])
		end

		return hypervisors
	end

	def self.getToken(username, password, keystone_endpoint)
		uri = URI("#{keystone_endpoint}/auth/tokens")
		req = Net::HTTP::Post.new(uri)
		req.content_type = 'application/json'

		req.body = {'auth' => {'identity' => {'methods' => ['password'],'password' => {'user' => {'name' => username,'domain' => {'id' => 'default'},'password' => password}}},'scope' => {'project' => {'name' => 'admin','domain' => {'id' => 'default'}}}}}.to_json
		req_options = { use_ssl: uri.scheme == 'https' }
	
		begin	
			res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
				http.request(req)
			end
		rescue
			$log.error "Unable to reach Openstack API."
			return nil
		end

		return res['X-Subject-Token']
	end

	def self.getHypervisorStates(token,nova_endpoint)
		uri = URI("#{nova_endpoint}/os-hypervisors/detail")
		req = Net::HTTP::Get.new(uri)
		req['X-Auth-Token'] = token

		req_options = { use_ssl: uri.scheme == 'https' }

		begin
			res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
				http.request(req)
			end
		rescue
			$log.error "Unable to reach Openstack API."
			return nil
		end

		begin
			json_response = JSON.parse(res.body)
		rescue
			$log.error "Invalid response from Openstack API."
			return nil
		end

		hypervisors = {}

		if not json_response.key?("hypervisors") ; then
			$log.warn "No hypervisor details returned from Openstack API."
			return nil
		end

		json_response['hypervisors'].each do |hypervisor|
			short_hostname = hypervisor['hypervisor_hostname'].split(".")[0]

			if hypervisor['running_vms'] > 0
				hypervisors[short_hostname] = "allocated"
			else
				hypervisors[short_hostname] = "idle"
			end
		end

		return hypervisors
	end
end
