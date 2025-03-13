# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require_relative "generic"
require_relative "composite_endpoint"
require_relative "address_endpoint"

module IO::Endpoint
	class BoundEndpoint < Generic
		def self.bound(endpoint, backlog: Socket::SOMAXCONN, close_on_exec: false)
			sockets = endpoint.bind
			
			sockets.each do |socket|
				socket.close_on_exec = close_on_exec
			end
			
			return self.new(endpoint, sockets, **endpoint.options)
		end
		
		def initialize(endpoint, sockets, **options)
			super(**options)
			
			@endpoint = endpoint
			@sockets = sockets
		end
		
		attr :endpoint
		attr :sockets
		
		# A endpoint for the local end of the bound socket.
		# @returns [CompositeEndpoint] A composite endpoint for the local end of the bound socket.
		def local_address_endpoint(**options)
			endpoints = @sockets.map do |socket|
				AddressEndpoint.new(socket.to_io.local_address, **options)
			end
			
			return CompositeEndpoint.new(endpoints)
		end
		
		# A endpoint for the remote end of the bound socket.
		# @returns [CompositeEndpoint] A composite endpoint for the remote end of the bound socket.
		def remote_address_endpoint(**options)
			endpoints = @sockets.map do |wrapper|
				AddressEndpoint.new(socket.to_io.remote_address, **options)
			end
			
			return CompositeEndpoint.new(endpoints)
		end
		
		def close
			@sockets.each(&:close)
			@sockets.clear
		end
		
		def to_s
			"bound:#{@endpoint}"
		end
		
		def inspect
			"\#<#{self.class} #{@sockets.size} bound sockets for #{@endpoint}>"
		end
		
		def bind(wrapper = self.wrapper, &block)
			@sockets.map do |server|
				if block_given?
					wrapper.schedule do
						yield server
					end
				else
					server.dup
				end
			end
		end
	end
	
	class Generic
		def bound(**options)
			BoundEndpoint.bound(self, **options)
		end
	end
end
