# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "protocol/http/body/readable"

module Protocol
	module HTTP1
		module Body
			# A body that reads all remaining data from the connection.
			class Remainder < HTTP::Body::Readable
				BLOCK_SIZE = 1024 * 64
				
				# block_size may be removed in the future. It is better managed by connection.
				def initialize(connection)
					@connection = connection
				end
				
				def empty?
					@connection.nil?
				end
				
				def discard
					if connection = @connection
						@connection = nil
						
						# Ensure no further requests can be read from the connection, as we are discarding the body which may not be fully read:
						connection.close_read
					end
				end
				
				def close(error = nil)
					self.discard
					
					super
				end
				
				def read
					@connection&.readpartial(BLOCK_SIZE)
				rescue EOFError
					if connection = @connection
						@connection = nil
						connection.receive_end_stream!
					end
					
					return nil
				end
				
				def inspect
					"\#<#{self.class} state=#{@connection ? 'open' : 'closed'}>"
				end
			end
		end
	end
end
