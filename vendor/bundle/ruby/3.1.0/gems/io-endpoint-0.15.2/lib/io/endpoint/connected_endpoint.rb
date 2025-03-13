# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require_relative "generic"
require_relative "composite_endpoint"
require_relative "socket_endpoint"

require "openssl"

module IO::Endpoint
	class ConnectedEndpoint < Generic
		def self.connected(endpoint, close_on_exec: false)
			socket = endpoint.connect
			
			socket.close_on_exec = close_on_exec
			
			return self.new(endpoint, socket, **endpoint.options)
		end
		
		def initialize(endpoint, socket, **options)
			super(**options)
			
			@endpoint = endpoint
			@socket = socket
		end
		
		attr :endpoint
		attr :socket
		
		# A endpoint for the local end of the bound socket.
		# @returns [AddressEndpoint] A endpoint for the local end of the connected socket.
		def local_address_endpoint(**options)
			AddressEndpoint.new(socket.to_io.local_address, **options)
		end
		
		# A endpoint for the remote end of the bound socket.
		# @returns [AddressEndpoint] A endpoint for the remote end of the connected socket.
		def remote_address_endpoint(**options)
			AddressEndpoint.new(socket.to_io.remote_address, **options)
		end
		
		def connect(wrapper = self.wrapper, &block)
			if block_given?
				yield @socket
			else
				return @socket.dup
			end
		end
		
		def close
			if @socket
				@socket.close
				@socket = nil
			end
		end
		
		def to_s
			"connected:#{@endpoint}"
		end
		
		def inspect
			"\#<#{self.class} #{@socket} connected for #{@endpoint}>"
		end
	end
		
	class Generic
		def connected(**options)
			ConnectedEndpoint.connected(self, **options)
		end
	end
end
