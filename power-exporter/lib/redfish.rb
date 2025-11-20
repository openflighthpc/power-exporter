#!/bin/ruby

require 'base64'
require 'uri'
require 'net/http'
require 'json'

module IDRACRedfish
	def self.getPower(host, username, password)
		if host.nil? or host == "" ; then
			return nil
		end

                if username.nil? or username == "" ; then
                        $log.error "No Redfish API username provided for #{host}"
                        return nil
                end

                if password.nil? or password == "" ; then
                        $log.error "No Redfish API password provided for #{host}"
                        return nil
                end

                auth_string = Base64.encode64("#{username}:#{password}").strip

                # Get power usage from Redfish API
                uri = URI("https://#{host}/redfish/v1/Chassis/System.Embedded.1/Power")
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE

                headers = {"Authorization" => "Basic #{auth_string}"}
                req = Net::HTTP::Get.new(uri.request_uri, headers)

                begin
                        res = http.request(req)
                        json = JSON.parse(res.body)

                        power = json['PowerControl'][0]['PowerConsumedWatts']
                        return power
                rescue
                        return nil
                end

                return nil
	end
end
