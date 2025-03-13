# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "frame"

module Protocol
	module HTTP2
		# Certain frames can have padding:
		# https://http2.github.io/http2-spec/#padding
		#
		# +---------------+
		# |Pad Length? (8)|
		# +---------------+-----------------------------------------------+
		# |                            Data (*)                         ...
		# +---------------------------------------------------------------+
		# |                           Padding (*)                       ...
		# +---------------------------------------------------------------+
		#
		module Padded
			def padded?
				flag_set?(PADDED)
			end
			
			def pack(data, padding_size: nil, maximum_size: nil)
				if padding_size
					set_flags(PADDED)
					
					buffer = String.new.b
					
					buffer << padding_size
					buffer << data
					
					if padding_size
						buffer << ("\0" * padding_size)
					end
					
					super buffer
				else
					clear_flags(PADDED)
					
					super data
				end
			end
			
			def unpack
				if padded?
					padding_size = @payload[0].ord
					
					# 1 byte for the padding octet, and padding_size bytes for the padding itself:
					data_size = @payload.bytesize - (1 + padding_size)
					
					if data_size < 0
						raise ProtocolError, "Invalid padding length: #{padding_size}"
					end
					
					return @payload.byteslice(1, data_size)
				else
					return @payload
				end
			end
		end
	end
end
