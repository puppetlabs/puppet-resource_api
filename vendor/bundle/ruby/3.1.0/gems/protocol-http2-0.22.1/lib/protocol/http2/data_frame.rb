# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "frame"
require_relative "padded"

module Protocol
	module HTTP2
		# DATA frames convey arbitrary, variable-length sequences of octets associated with a stream. One or more DATA frames are used, for instance, to carry HTTP request or response payloads.
		# 
		# DATA frames MAY also contain padding. Padding can be added to DATA frames to obscure the size of messages.
		# 
		# +---------------+
		# |Pad Length? (8)|
		# +---------------+-----------------------------------------------+
		# |                            Data (*)                         ...
		# +---------------------------------------------------------------+
		# |                           Padding (*)                       ...
		# +---------------------------------------------------------------+
		#
		class DataFrame < Frame
			include Padded
			
			TYPE = 0x0
			
			def end_stream?
				flag_set?(END_STREAM)
			end
			
			def pack(data, *arguments, **options)
				if data
					super
				else
					@length = 0
					set_flags(END_STREAM)
				end
			end
			
			def apply(connection)
				connection.receive_data(self)
			end
			
			def inspect
				"\#<#{self.class} stream_id=#{@stream_id} flags=#{@flags} #{@length || 0}b>"
			end
		end
	end
end
