#!/bin/ruby

module FakePower
	def self.getPower(min, max)
                if min.nil? or not min.is_a?(Numeric) ; then
                        min = 100
                end

                if max.nil? or not max.is_a?(Numeric) ; then
                        max = 500
                end

                if min >= max ; then
                        min = 100
                        max = 500
                end

                # Return a random value between min and max
                power = rand(max - min) + min

		return power
	end
end
