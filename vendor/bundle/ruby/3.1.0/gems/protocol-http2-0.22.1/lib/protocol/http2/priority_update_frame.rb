# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require_relative "frame"
require_relative "padded"
require_relative "continuation_frame"

module Protocol
	module HTTP2
		# The PRIORITY_UPDATE frame is used by clients to signal the initial priority of a response, or to reprioritize a response or push stream. It carries the stream ID of the response and the priority in ASCII text, using the same representation as the Priority header field value.
		# 
		# +-+-------------+-----------------------------------------------+
		# |R|                 Prioritized Stream ID (31)                  |
		# +-+-----------------------------+-------------------------------+
		# |                    Priority Field Value (*)                 ...
		# +---------------------------------------------------------------+
		#
		class PriorityUpdateFrame < Frame
			TYPE = 0x10
			FORMAT = "N".freeze
			
			def unpack
				data = super
				
				prioritized_stream_id = data.unpack1(FORMAT)
				
				return prioritized_stream_id, data.byteslice(4, data.bytesize - 4)
			end
			
			def pack(prioritized_stream_id, data, **options)
				super([prioritized_stream_id].pack(FORMAT) + data, **options)
			end
			
			def apply(connection)
				connection.receive_priority_update(self)
			end
		end
	end
end
