#!/bin/ruby

module IPMI_SSH
	def self.getPower(host, sensors)
                if host.nil? or host == "" ; then
                        return nil
                end

                if sensors.nil? ; then
                        $log.error "No ipmi sensors provided to lookup for #{host}"
                        return nil
                end

	        # Get ipmitool sensor output from the host
                ipmitool_output = `ssh #{host} "/usr/bin/sudo /usr/bin/ipmitool sensor list" 2>/dev/null`

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
