# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "connection"

module Protocol
	module HTTP2
		class Client < Connection
			def initialize(framer)
				super(framer, 1)
			end
			
			def local_stream_id?(id)
				id.odd?
			end
			
			def remote_stream_id?(id)
				id.even?
			end
			
			def valid_remote_stream_id?(stream_id)
				stream_id.even?
			end
			
			def send_connection_preface(settings = [])
				if @state == :new
					@framer.write_connection_preface
					
					send_settings(settings)
					
					yield if block_given?
					
					read_frame do |frame|
						unless frame.is_a? SettingsFrame
							raise ProtocolError, "First frame must be #{SettingsFrame}, but got #{frame.class}"
						end
					end
				else
					raise ProtocolError, "Cannot send connection preface in state #{@state}"
				end
			end
			
			def create_push_promise_stream
				raise ProtocolError, "Cannot create push promises from client!"
			end
			
			def receive_push_promise(frame)
				if frame.stream_id == 0
					raise ProtocolError, "Cannot receive headers for stream 0!"
				end
				
				if stream = @streams[frame.stream_id]
					# This is almost certainly invalid:
					promised_stream, request_headers = stream.receive_push_promise(frame)
					
					return promised_stream, request_headers
				end
			end
		end
	end
end
