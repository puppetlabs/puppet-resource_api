# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "frame"

module Protocol
	module HTTP2
		# The GOAWAY frame is used to initiate shutdown of a connection or to signal serious error conditions. GOAWAY allows an endpoint to gracefully stop accepting new streams while still finishing processing of previously established streams. This enables administrative actions, like server maintenance.
		#
		# +-+-------------------------------------------------------------+
		# |R|                  Last-Stream-ID (31)                        |
		# +-+-------------------------------------------------------------+
		# |                      Error Code (32)                          |
		# +---------------------------------------------------------------+
		# |                  Additional Debug Data (*)                    |
		# +---------------------------------------------------------------+
		#
		class GoawayFrame < Frame
			TYPE = 0x7
			FORMAT = "NN"
			
			def connection?
				true
			end
			
			def unpack
				data = super
				
				last_stream_id, error_code = data.unpack(FORMAT)
				
				return last_stream_id, error_code, data.slice(8, data.bytesize-8)
			end
			
			def pack(last_stream_id, error_code, data)
				super [last_stream_id, error_code].pack(FORMAT) + data
			end
			
			def apply(connection)
				connection.receive_goaway(self)
			end
		end
	end
end
