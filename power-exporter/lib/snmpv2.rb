#!/bin/ruby

module SNMPv2
	def self.getPower(host, community, oids)
		if host.nil? or host == "" ; then
			return nil
		end

		if oids.nil? ; then
			$log.error "No SNMP oids provided to lookup for #{host}"
			return nil
		end

		if community.nil? or community == "" ; then
			$log.error "No SNMP community provided for #{host}"
			return nil
		end

		# Get snmpget output
		snmp_output = `snmpget -Oqv -v2c -t5 -r1 -c #{community} #{host} #{oids.join(' ')} 2>/dev/null`

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
