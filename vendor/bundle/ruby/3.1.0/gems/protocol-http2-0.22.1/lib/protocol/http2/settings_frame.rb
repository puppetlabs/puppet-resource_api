# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "ping_frame"

module Protocol
	module HTTP2
		class Settings
			HEADER_TABLE_SIZE = 0x1
			ENABLE_PUSH = 0x2
			MAXIMUM_CONCURRENT_STREAMS = 0x3
			INITIAL_WINDOW_SIZE = 0x4
			MAXIMUM_FRAME_SIZE = 0x5
			MAXIMUM_HEADER_LIST_SIZE = 0x6
			ENABLE_CONNECT_PROTOCOL = 0x8
			NO_RFC7540_PRIORITIES = 0x9
			
			ASSIGN = [
				nil,
				:header_table_size=,
				:enable_push=,
				:maximum_concurrent_streams=,
				:initial_window_size=,
				:maximum_frame_size=,
				:maximum_header_list_size=,
				nil,
				:enable_connect_protocol=,
				:no_rfc7540_priorities=,
			]
			
			def initialize
				# These limits are taken from the RFC:
				# https://tools.ietf.org/html/rfc7540#section-6.5.2
				@header_table_size = 4096
				@enable_push = 1
				@maximum_concurrent_streams = 0xFFFFFFFF
				@initial_window_size = 0xFFFF # 2**16 - 1
				@maximum_frame_size = 0x4000 # 2**14
				@maximum_header_list_size = 0xFFFFFFFF
				@enable_connect_protocol = 0
				@no_rfc7540_priorities = 0
			end
			
			# Allows the sender to inform the remote endpoint of the maximum size of the header compression table used to decode header blocks, in octets.
			attr_accessor :header_table_size
			
			# This setting can be used to disable server push. An endpoint MUST NOT send a PUSH_PROMISE frame if it receives this parameter set to a value of 0.
			attr :enable_push
			
			def enable_push= value
				if value == 0 or value == 1
					@enable_push = value
				else
					raise ProtocolError, "Invalid value for enable_push: #{value}"
				end
			end
			
			def enable_push?
				@enable_push == 1
			end
			
			# Indicates the maximum number of concurrent streams that the sender will allow.
			attr_accessor :maximum_concurrent_streams
			
			# Indicates the sender's initial window size (in octets) for stream-level flow control.
			attr :initial_window_size
			
			def initial_window_size= value
				if value <= MAXIMUM_ALLOWED_WINDOW_SIZE
					@initial_window_size = value
				else
					raise ProtocolError, "Invalid value for initial_window_size: #{value} > #{MAXIMUM_ALLOWED_WINDOW_SIZE}"
				end
			end
			
			# Indicates the size of the largest frame payload that the sender is willing to receive, in octets.
			attr :maximum_frame_size
			
			def maximum_frame_size= value
				if value > MAXIMUM_ALLOWED_FRAME_SIZE
					raise ProtocolError, "Invalid value for maximum_frame_size: #{value} > #{MAXIMUM_ALLOWED_FRAME_SIZE}"
				elsif value < MINIMUM_ALLOWED_FRAME_SIZE
					raise ProtocolError, "Invalid value for maximum_frame_size: #{value} < #{MINIMUM_ALLOWED_FRAME_SIZE}"
				else
					@maximum_frame_size = value
				end
			end
			
			# This advisory setting informs a peer of the maximum size of header list that the sender is prepared to accept, in octets.
			attr_accessor :maximum_header_list_size
			
			attr :enable_connect_protocol
			
			def enable_connect_protocol= value
				if value == 0 or value == 1
					@enable_connect_protocol = value
				else
					raise ProtocolError, "Invalid value for enable_connect_protocol: #{value}"
				end
			end
			
			def enable_connect_protocol?
				@enable_connect_protocol == 1
			end
			
			attr :no_rfc7540_priorities
			
			def no_rfc7540_priorities= value
				if value == 0 or value == 1
					@no_rfc7540_priorities = value
				else
					raise ProtocolError, "Invalid value for no_rfc7540_priorities: #{value}"
				end
			end
			
			def no_rfc7540_priorities?
				@no_rfc7540_priorities == 1
			end
			
			def update(changes)
				changes.each do |key, value|
					if name = ASSIGN[key]
						self.send(name, value)
					end
				end
			end
		end
		
		class PendingSettings
			def initialize(current = Settings.new)
				@current = current
				@pending = current.dup
				
				@queue = []
			end
			
			attr :current
			attr :pending
			
			def append(changes)
				@queue << changes
				@pending.update(changes)
			end
			
			def acknowledge
				if changes = @queue.shift
					@current.update(changes)
					
					return changes
				else
					raise ProtocolError, "Cannot acknowledge settings, no changes pending"
				end
			end
			
			def header_table_size
				@current.header_table_size
			end
			
			def enable_push
				@current.enable_push
			end
			
			def maximum_concurrent_streams
				@current.maximum_concurrent_streams
			end
			
			def initial_window_size
				@current.initial_window_size
			end
			
			def maximum_frame_size
				@current.maximum_frame_size
			end
			
			def maximum_header_list_size
				@current.maximum_header_list_size
			end
			
			def enable_connect_protocol
				@current.enable_connect_protocol
			end
		end
		
		# The SETTINGS frame conveys configuration parameters that affect how endpoints communicate, such as preferences and constraints on peer behavior. The SETTINGS frame is also used to acknowledge the receipt of those parameters. Individually, a SETTINGS parameter can also be referred to as a "setting".
		# 
		# +-------------------------------+
		# |       Identifier (16)         |
		# +-------------------------------+-------------------------------+
		# |                        Value (32)                             |
		# +---------------------------------------------------------------+
		#
		class SettingsFrame < Frame
			TYPE = 0x4
			FORMAT = "nN".freeze
			
			include Acknowledgement
			
			def connection?
				true
			end
			
			def unpack
				if buffer = super
					# TODO String#each_slice, or #each_unpack would be nice.
					buffer.scan(/....../m).map{|s| s.unpack(FORMAT)}
				else
					[]
				end
			end
			
			def pack(settings = [])
				super(settings.map{|s| s.pack(FORMAT)}.join)
			end
			
			def apply(connection)
				connection.receive_settings(self)
			end
			
			def read_payload(stream)
				super
				
				if @stream_id != 0
					raise ProtocolError, "Settings apply to connection only, but stream_id was given"
				end
				
				if acknowledgement? and @length != 0
					raise FrameSizeError, "Settings acknowledgement must not contain payload: #{@payload.inspect}"
				end
				
				if (@length % 6) != 0
					raise FrameSizeError, "Invalid frame length"
				end
			end
		end
	end
end
