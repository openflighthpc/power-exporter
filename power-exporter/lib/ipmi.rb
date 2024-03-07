#!/bin/ruby

module IPMI
	def self.getPower(host, username, password, sensors)
                if host.nil? or host == "" ; then
                        return nil
                end

                if sensors.nil? ; then
                        $log.error "No ipmi sensors provided to lookup for #{host}"
                        return nil
                end

                if username.nil? or username == "" ; then
                        $log.error "No ipmi username provided for #{host}"
                        return nil
                end

		if password.nil? or password == "" ; then
                        $log.error "No ipmi password provided for #{host}"
                        return nil
                end

	        # Get ipmitool sensor output from the host
        	ipmitool_output = `ipmitool -I lanplus -H #{host} -U #{username} -P #{password} sensor list`

		if ipmitool_output == "" ; then
			return nil
		end

        	power = 0.0

	        ipmitool_output.each_line do |line|
        	        # CPU1 Temperature | 65.000     | degrees C  | ok    | 0.000     | 0.000     | 0.000     | 98.000    | 101.000   | 104.000   
	                parts = line.split("|")
        	        name = parts[0].strip

	                # Skip if its not a sensor we care about
	                next if not sensors.include?(name)

	                # Accumlate power usage from each sensor 
	                reading = parts[1].strip.to_f
	                power += reading
	        end

	        return power
	end
end
