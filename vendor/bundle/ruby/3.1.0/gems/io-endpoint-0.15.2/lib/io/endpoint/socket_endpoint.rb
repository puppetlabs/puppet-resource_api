# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require_relative "generic"

module IO::Endpoint
	# This class doesn't exert ownership over the specified socket, wraps a native ::IO.
	class SocketEndpoint < Generic
		def initialize(socket, **options)
			super(**options)
			
			@socket = socket
		end
		
		def to_s
			"socket:#{@socket}"
		end
		
		def inspect
			"\#<#{self.class} #{@socket.inspect}>"
		end
		
		attr :socket
		
		def bind(&block)
			if block_given?
				yield @socket
			else
				return @socket
			end
		end
		
		def connect(&block)
			if block_given?
				yield @socket
			else
				return @socket
			end
		end
	end
	
	def self.socket(socket, **options)
		SocketEndpoint.new(socket, **options)
	end
end
