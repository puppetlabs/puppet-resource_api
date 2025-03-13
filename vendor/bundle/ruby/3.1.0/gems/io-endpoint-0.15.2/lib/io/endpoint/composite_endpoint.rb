# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require_relative "generic"

module IO::Endpoint
	# A composite endpoint is a collection of endpoints that are used in order.
	class CompositeEndpoint < Generic
		def initialize(endpoints, **options)
			super(**options)
			
			# If any options were provided, propagate them to the endpoints:
			if options.any?
				endpoints = endpoints.map{|endpoint| endpoint.with(**options)}
			end
			
			@endpoints = endpoints
		end
		
		def to_s
			"composite:#{@endpoints.join(",")}"
		end
		
		def inspect
			"\#<#{self.class} endpoints=#{@endpoints}>"
		end
		
		def with(**options)
			self.class.new(endpoints.map{|endpoint| endpoint.with(**options)}, **@options.merge(options))
		end
		
		attr :endpoints
		
		# The number of endpoints in the composite endpoint.
		def size
			@endpoints.size
		end
		
		def each(&block)
			@endpoints.each do |endpoint|
				endpoint.each(&block)
			end
		end
		
		def connect(wrapper = self.wrapper, &block)
			last_error = nil
			
			@endpoints.each do |endpoint|
				begin
					return endpoint.connect(wrapper, &block)
				rescue => last_error
				end
			end
			
			raise last_error
		end
		
		def bind(wrapper = self.wrapper, &block)
			if block_given?
				@endpoints.each do |endpoint|
					endpoint.bind(&block)
				end
			else
				@endpoints.map(&:bind).flatten.compact
			end
		end
	end
	
	def self.composite(*endpoints, **options)
		CompositeEndpoint.new(endpoints, **options)
	end
end
