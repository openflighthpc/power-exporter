#!/bin/ruby

module SNMPv3
        def self.getPower(host, username, oids)
		if host.nil? or host == "" ; then
                        return nil
                end

		if username.nil? or username == "" ; then
                        $log.error "No SNMPv3 username provided for #{host}"
                        return nil
                end

		if oids.nil? ; then
                        $log.error "No SNMPv3 oids provided to lookup for #{host}"
                        return nil
                end

		# Get snmpget output
                snmp_output = `snmpget -Oqv -v3 -t5 -r1 -l noAuthNoPriv -u #{username} #{host} #{oids.join(' ')} 2>/dev/null`

                if snmp_output == "" ; then
                        return nil
                end

                total = 0.0

                snmp_output.each_line do |line|
                        reading = line.to_f
                        total += reading
                end

                return total

	end
end
