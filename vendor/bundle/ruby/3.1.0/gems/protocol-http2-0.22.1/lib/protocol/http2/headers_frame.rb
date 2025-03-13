# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "frame"
require_relative "padded"
require_relative "continuation_frame"

module Protocol
	module HTTP2
		# The HEADERS frame is used to open a stream, and additionally carries a header block fragment. HEADERS frames can be sent on a stream in the "idle", "reserved (local)", "open", or "half-closed (remote)" state.
		# 
		# +---------------+
		# |Pad Length? (8)|
		# +-+-------------+-----------------------------------------------+
		# |E|                 Stream Dependency? (31)                     |
		# +-+-------------+-----------------------------------------------+
		# |  Weight? (8)  |
		# +-+-------------+-----------------------------------------------+
		# |                   Header Block Fragment (*)                 ...
		# +---------------------------------------------------------------+
		# |                           Padding (*)                       ...
		# +---------------------------------------------------------------+
		#
		class HeadersFrame < Frame
			include Continued, Padded
			
			TYPE = 0x1
			
			def priority?
				flag_set?(PRIORITY)
			end
			
			def end_stream?
				flag_set?(END_STREAM)
			end
			
			def unpack
				data = super
				
				if priority?
					# We no longer support priority frames, so strip the data:
					data = data.byteslice(5, data.bytesize - 5)
				end
				
				return data
			end
			
			def pack(data, *arguments, **options)
				buffer = String.new.b
				
				buffer << data
				
				super(buffer, *arguments, **options)
			end
			
			def apply(connection)
				connection.receive_headers(self)
			end
			
			def inspect
				"\#<#{self.class} stream_id=#{@stream_id} flags=#{@flags} #{@length || 0}b>"
			end
		end
	end
end
