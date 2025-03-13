# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "frame"

module Protocol
	module HTTP2
		ACKNOWLEDGEMENT = 0x1
		
		module Acknowledgement
			def acknowledgement?
				flag_set?(ACKNOWLEDGEMENT)
			end
			
			def acknowledgement!
				set_flags(ACKNOWLEDGEMENT)
			end
			
			def acknowledge
				frame = self.class.new
				
				frame.length = 0
				frame.set_flags(ACKNOWLEDGEMENT)
				
				return frame
			end
		end
		
		# The PING frame is a mechanism for measuring a minimal round-trip time from the sender, as well as determining whether an idle connection is still functional. PING frames can be sent from any endpoint.
		#
		# +---------------------------------------------------------------+
		# |                                                               |
		# |                      Opaque Data (64)                         |
		# |                                                               |
		# +---------------------------------------------------------------+
		#
		class PingFrame < Frame
			TYPE = 0x6
			
			include Acknowledgement
			
			def connection?
				true
			end
			
			def apply(connection)
				connection.receive_ping(self)
			end
			
			def acknowledge
				frame = super
				
				frame.pack self.unpack
				
				return frame
			end
			
			def read_payload(stream)
				super
				
				if @stream_id != 0
					raise ProtocolError, "Settings apply to connection only, but stream_id was given"
				end
				
				if @length != 8
					raise FrameSizeError, "Invalid frame length: #{@length} != 8!"
				end
			end
		end
	end
end
