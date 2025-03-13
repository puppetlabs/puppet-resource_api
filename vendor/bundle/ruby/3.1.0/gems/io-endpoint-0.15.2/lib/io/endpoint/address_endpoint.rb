# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require "socket"

require_relative "generic"
require_relative "wrapper"

module IO::Endpoint
	class AddressEndpoint < Generic
		def initialize(address, **options)
			super(**options)
			
			@address = address
		end
		
		def to_s
			case @address.afamily
			when Socket::AF_INET
				"inet:#{@address.inspect_sockaddr}"
			when Socket::AF_INET6
				"inet6:#{@address.inspect_sockaddr}"
			else
				"address:#{@address.inspect_sockaddr}"
			end
		end
		
		def inspect
			"\#<#{self.class} address=#{@address.inspect}>"
		end
		
		attr :address
		
		# Bind a socket to the given address. If a block is given, the socket will be automatically closed when the block exits.
		# @yield {|socket| ...}	An optional block which will be passed the socket.
		#   @parameter socket [Socket] The socket which has been bound.
		# @return [Array(Socket)] the bound socket
		def bind(wrapper = self.wrapper, &block)
			[wrapper.bind(@address, **@options, &block)]
		end
		
		# Connects a socket to the given address. If a block is given, the socket will be automatically closed when the block exits.
		# @return [Socket] the connected socket
		def connect(wrapper = self.wrapper, &block)
			wrapper.connect(@address, **@options, &block)
		end
	end
end
