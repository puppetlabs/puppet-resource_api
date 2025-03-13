# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2023, by Thomas Morgan.

require "protocol/http/body/readable"

module Protocol
	module HTTP1
		module Body
			class Chunked < HTTP::Body::Readable
				CRLF = "\r\n"
				
				def initialize(connection, headers)
					@connection = connection
					@finished = false
					
					@headers = headers
					
					@length = 0
					@count = 0
				end
				
				attr :count
				
				def length
					# We only know the length once we've read everything. This is because the length is not known until the final chunk is read.
					if @finished
						@length
					end
				end
				
				def empty?
					@connection.nil?
				end
				
				def close(error = nil)
					if connection = @connection
						@connection = nil
						
						unless @finished
							connection.close_read
						end
					end
					
					super
				end
				
				VALID_CHUNK_LENGTH = /\A[0-9a-fA-F]+\z/
				
				# Follows the procedure outlined in https://tools.ietf.org/html/rfc7230#section-4.1.3
				def read
					if !@finished
						if @connection
							length, _extensions = @connection.read_line.split(";", 2)
							
							unless length =~ VALID_CHUNK_LENGTH
								raise BadRequest, "Invalid chunk length: #{length.inspect}"
							end
							
							# It is possible this line contains chunk extension, so we use `to_i` to only consider the initial integral part:
							length = Integer(length, 16)
							
							if length == 0
								read_trailer
								
								# The final chunk has been read and the connection is now closed:
								@connection.receive_end_stream!
								@connection = nil
								@finished = true
								
								return nil
							end
							
							# Read trailing CRLF:
							chunk = @connection.read(length + 2)
							
							if chunk.bytesize == length + 2
								# ...and chomp it off:
								chunk.chomp!(CRLF)
								
								@length += length
								@count += 1
								
								return chunk
							else
								# The connection has been closed before we have read the requested length:
								@connection.close_read
								@connection = nil
							end
						end
						
						# If the connection has been closed before we have read the final chunk, raise an error:
						raise EOFError, "connection closed before expected length was read!"
					end
				end
				
				def inspect
					"\#<#{self.class} #{@length} bytes read in #{@count} chunks>"
				end
				
				private
				
				def read_trailer
					while line = @connection.read_line?
						# Empty line indicates end of trailer:
						break if line.empty?
						
						if match = line.match(HEADER)
							@headers.add(match[1], match[2])
						else
							raise BadHeader, "Could not parse header: #{line.inspect}"
						end
					end
				end
			end
		end
	end
end
