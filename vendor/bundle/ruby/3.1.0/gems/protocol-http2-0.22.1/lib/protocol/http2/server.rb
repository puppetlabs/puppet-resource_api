# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "connection"

module Protocol
	module HTTP2
		class Server < Connection
			def initialize(framer)
				super(framer, 2)
			end
			
			def local_stream_id?(id)
				id.even?
			end
			
			def remote_stream_id?(id)
				id.odd?
			end
			
			def valid_remote_stream_id?(stream_id)
				stream_id.odd?
			end
			
			def read_connection_preface(settings = [])
				if @state == :new
					@framer.read_connection_preface
					
					send_settings(settings)
					
					read_frame do |frame|
						unless frame.is_a? SettingsFrame
							raise ProtocolError, "First frame must be #{SettingsFrame}, but got #{frame.class}"
						end
					end
				else
					raise ProtocolError, "Cannot read connection preface in state #{@state}"
				end
			end
			
			def accept_push_promise_stream(stream_id, &block)
				raise ProtocolError, "Cannot accept push promises on server!"
			end
			
			def enable_push?
				@remote_settings.enable_push?
			end
		end
	end
end
