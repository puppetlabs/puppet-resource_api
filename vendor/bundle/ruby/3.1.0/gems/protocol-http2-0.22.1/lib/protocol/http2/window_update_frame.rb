# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "frame"
require_relative "window"

module Protocol
	module HTTP2
		# The WINDOW_UPDATE frame is used to implement flow control.
		#
		# +-+-------------------------------------------------------------+
		# |R|              Window Size Increment (31)                     |
		# +-+-------------------------------------------------------------+
		#
		class WindowUpdateFrame < Frame
			TYPE = 0x8
			FORMAT = "N"
			
			def pack(window_size_increment)
				super [window_size_increment].pack(FORMAT)
			end
			
			def unpack
				super.unpack1(FORMAT)
			end
			
			def read_payload(stream)
				super
				
				if @length != 4
					raise FrameSizeError, "Invalid frame length: #{@length} != 4!"
				end
			end
			
			def apply(connection)
				connection.receive_window_update(self)
			end
		end
	end
end
