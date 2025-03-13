# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "protocol/http/body/readable"

module Protocol
	module HTTP1
		module Body
			class Fixed < HTTP::Body::Readable
				def initialize(connection, length)
					@connection = connection
					
					@length = length
					@remaining = length
				end
				
				attr :length
				attr :remaining
				
				def empty?
					@connection.nil? or @remaining == 0
				end
				
				def close(error = nil)
					if connection = @connection
						@connection = nil
						
						unless @remaining == 0
							connection.close_read
						end
					end
					
					super
				end
				
				# @raises EOFError if the connection is closed before the expected length is read.
				def read
					if @remaining > 0
						if @connection
							# `readpartial` will raise `EOFError` if the connection is finished, or `IOError` if the connection is closed.
							chunk = @connection.readpartial(@remaining)
							
							@remaining -= chunk.bytesize
							
							if @remaining == 0
								@connection.receive_end_stream!
								@connection = nil
							end
							
							return chunk
						end
						
						# If the connection has been closed before we have read the expected length, raise an error:
						raise EOFError, "connection closed before expected length was read!"
					end
				end
				
				def inspect
					"\#<#{self.class} length=#{@length} remaining=#{@remaining} state=#{@connection ? 'open' : 'closed'}>"
				end
			end
		end
	end
end
