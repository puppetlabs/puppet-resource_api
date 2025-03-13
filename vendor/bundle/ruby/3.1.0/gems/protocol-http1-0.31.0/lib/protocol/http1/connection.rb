# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2019, by Brian Morearty.
# Copyright, 2020, by Bruno Sutic.
# Copyright, 2023-2024, by Thomas Morgan.
# Copyright, 2024, by Anton Zhuravsky.

require "protocol/http/headers"

require_relative "reason"
require_relative "error"

require_relative "body/chunked"
require_relative "body/fixed"
require_relative "body/remainder"
require "protocol/http/body/head"

require "protocol/http/methods"

module Protocol
	module HTTP1
		CONTENT_LENGTH = "content-length"
		
		TRANSFER_ENCODING = "transfer-encoding"
		CHUNKED = "chunked"
		
		CONNECTION = "connection"
		CLOSE = "close"
		KEEP_ALIVE = "keep-alive"
		
		HOST = "host"
		UPGRADE = "upgrade"
		
		# HTTP/1.x request line parser:
		TOKEN = /[!#$%&'*+\-\.\^_`|~0-9a-zA-Z]+/.freeze
		REQUEST_LINE = /\A(#{TOKEN}) ([^\s]+) (HTTP\/\d.\d)\z/.freeze
		
		# HTTP/1.x header parser:
		FIELD_NAME = TOKEN
		FIELD_VALUE = /[^\000-\037]*/.freeze
		HEADER = /\A(#{FIELD_NAME}):\s*(#{FIELD_VALUE})\s*\z/.freeze
		
		VALID_FIELD_NAME = /\A#{FIELD_NAME}\z/.freeze
		VALID_FIELD_VALUE = /\A#{FIELD_VALUE}\z/.freeze
		
		DEFAULT_MAXIMUM_LINE_LENGTH = 8192
		
		class Connection
			CRLF = "\r\n"
			HTTP10 = "HTTP/1.0"
			HTTP11 = "HTTP/1.1"
			
			def initialize(stream, persistent: true, state: :idle, maximum_line_length: DEFAULT_MAXIMUM_LINE_LENGTH)
				@stream = stream
				
				@persistent = persistent
				@state = state
				
				@count = 0
				
				@maximum_line_length = maximum_line_length
			end
			
			attr :stream
			
			# Whether the connection is persistent.
			# This determines what connection headers are sent in the response and whether
			# the connection can be reused after the response is sent.
			# This setting is automatically managed according to the nature of the request
			# and response.
			# Changing to false is safe.
			# Changing to true from outside this class should generally be avoided and,
			# depending on the response semantics, may be reset to false anyway.
			attr_accessor :persistent
			
			# The current state of the connection.
			#
			# ```
			#                          ┌────────┐
			#                          │        │
			# ┌───────────────────────►│  idle  │
			# │                        │        │
			# │                        └───┬────┘
			# │                            │
			# │                            │ send request /
			# │                            │ receive request
			# │                            │
			# │                            ▼
			# │                        ┌────────┐
			# │                recv ES │        │ send ES
			# │           ┌────────────┤  open  ├────────────┐
			# │           │            │        │            │
			# │           ▼            └───┬────┘            ▼
			# │      ┌──────────┐          │           ┌──────────┐
			# │      │   half   │          │           │   half   │
			# │      │  closed  │          │ send R /  │  closed  │
			# │      │ (remote) │          │ recv R    │ (local)  │
			# │      └────┬─────┘          │           └─────┬────┘
			# │           │                │                 │
			# │           │ send ES /      │       recv ES / │
			# │           │ close          ▼           close │
			# │           │            ┌────────┐            │
			# │           └───────────►│        │◄───────────┘
			# │                        │ closed │
			# └────────────────────────┤        │
			#         persistent       └────────┘
			# ```
			#
			# - `ES`: the body was fully received or sent (end of stream).
			# - `R`: the connection was closed unexpectedly (reset).
			#
			# State transition methods use a trailing "!".
			attr_accessor :state
			
			def idle?
				@state == :idle
			end
			
			def open?
				@state == :open
			end
			
			def half_closed_local?
				@state == :half_closed_local
			end
			
			def half_closed_remote?
				@state == :half_closed_remote
			end
			
			def closed?
				@state == :closed
			end
			
			# The number of requests processed.
			attr :count
			
			def persistent?(version, method, headers)
				if method == HTTP::Methods::CONNECT
					return false
				end
				
				if version == HTTP10
					if connection = headers[CONNECTION]
						return connection.keep_alive?
					else
						return false
					end
				else # HTTP/1.1+
					if connection = headers[CONNECTION]
						return !connection.close?
					else
						return true
					end
				end
			end
			
			# Write the appropriate header for connection persistence.
			def write_connection_header(version)
				if version == HTTP10
					@stream.write("connection: keep-alive\r\n") if @persistent
				else
					@stream.write("connection: close\r\n") unless @persistent
				end
			end
			
			def write_upgrade_header(upgrade)
				@stream.write("connection: upgrade\r\nupgrade: #{upgrade}\r\n")
			end
			
			# Indicates whether the connection has been hijacked meaning its
			# IO has been handed over and is not usable anymore.
			# @return [Boolean] hijack status
			def hijacked?
				@stream.nil?
			end
			
			# Effectively close the connection and return the underlying IO.
			# @return [IO] the underlying non-blocking IO.
			def hijack!
				@persistent = false
				
				if stream = @stream
					@stream = nil
					stream.flush
					
					@state = :hijacked
					self.closed
					
					return stream
				end
			end
			
			def close_read
				@persistent = false
				@stream&.close_read
				self.receive_end_stream!
			end
			
			# Close the connection and underlying stream.
			def close(error = nil)
				@persistent = false
				
				if stream = @stream
					@stream = nil
					stream.close
				end
				
				unless closed?
					@state = :closed
					self.closed(error)
				end
			end
			
			def open!
				unless @state == :idle
					raise ProtocolError, "Cannot open connection in state: #{@state}!"
				end
				
				@state = :open
				
				return self
			end
			
			def write_request(authority, method, target, version, headers)
				open!
				
				@stream.write("#{method} #{target} #{version}\r\n")
				@stream.write("host: #{authority}\r\n") if authority
				
				write_headers(headers)
			end
			
			def write_response(version, status, headers, reason = Reason::DESCRIPTIONS[status])
				unless @state == :open or @state == :half_closed_remote
					raise ProtocolError, "Cannot write response in state: #{@state}!"
				end
				
				# Safari WebSockets break if no reason is given:
				@stream.write("#{version} #{status} #{reason}\r\n")
				
				write_headers(headers)
			end
			
			def write_interim_response(version, status, headers, reason = Reason::DESCRIPTIONS[status])
				unless @state == :open or @state == :half_closed_remote
					raise ProtocolError, "Cannot write interim response in state: #{@state}!"
				end
				
				@stream.write("#{version} #{status} #{reason}\r\n")
				
				write_headers(headers)
				
				@stream.write("\r\n")
				@stream.flush
			end
			
			def write_headers(headers)
				headers.each do |name, value|
					# Convert it to a string:
					name = name.to_s
					value = value.to_s
					
					# Validate it:
					unless name.match?(VALID_FIELD_NAME)
						raise BadHeader, "Invalid header name: #{name.inspect}"
					end
					
					unless value.match?(VALID_FIELD_VALUE)
						raise BadHeader, "Invalid header value for #{name}: #{value.inspect}"
					end
					
					# Write it:
					@stream.write("#{name}: #{value}\r\n")
				end
			end
			
			def readpartial(length)
				@stream.readpartial(length)
			end
			
			def read(length)
				@stream.read(length)
			end
			
			def read_line?
				if line = @stream.gets(CRLF, @maximum_line_length)
					unless line.chomp!(CRLF)
						# This basically means that the request line, response line, header, or chunked length line is too long.
						raise LineLengthError, "Line too long!"
					end
				end
				
				return line
			end
			
			def read_line
				read_line? or raise EOFError
			end
			
			def read_request_line
				return unless line = read_line?
				
				if match = line.match(REQUEST_LINE)
					_, method, path, version = *match
				else
					raise InvalidRequest, line.inspect
				end
				
				return method, path, version
			end
			
			def read_request
				open!
				
				method, path, version = read_request_line
				return unless method
				
				headers = read_headers
				
				# If we are not persistent, we can't become persistent even if the request might allow it:
				if @persistent
					# In other words, `@persistent` can only transition from true to false.
					@persistent = persistent?(version, method, headers)
				end
				
				body = read_request_body(method, headers)
				
				unless body
					self.receive_end_stream!
				end
				
				@count += 1
				
				if block_given?
					yield headers.delete(HOST), method, path, version, headers, body
				else
					return headers.delete(HOST), method, path, version, headers, body
				end
			end
			
			def read_response_line
				version, status, reason = read_line.split(/\s+/, 3)
				
				status = Integer(status)
				
				return version, status, reason
			end
			
			private def interim_status?(status)
				status != 101 and status >= 100 and status < 200
			end
			
			def read_response(method)
				unless @state == :open or @state == :half_closed_local
					raise ProtocolError, "Cannot read response in state: #{@state}!"
				end
				
				version, status, reason = read_response_line
				
				headers = read_headers
				
				if @persistent
					@persistent = persistent?(version, method, headers)
				end
				
				unless interim_status?(status)
					body = read_response_body(method, status, headers)
					
					unless body
						self.receive_end_stream!
					end
					
					@count += 1
				end
				
				if block_given?
					yield version, status, reason, headers, body
				else
					return version, status, reason, headers, body
				end
			end
			
			def read_headers
				fields = []
				
				while line = read_line
					# Empty line indicates end of headers:
					break if line.empty?
					
					if match = line.match(HEADER)
						fields << [match[1], match[2]]
					else
						raise BadHeader, "Could not parse header: #{line.inspect}"
					end
				end
				
				return HTTP::Headers.new(fields)
			end
			
			def send_end_stream!
				if @state == :open
					@state = :half_closed_local
				elsif @state == :half_closed_remote
					self.close!
				else
					raise ProtocolError, "Cannot send end stream in state: #{@state}!"
				end
			end
			
			# @param protocol [String] the protocol to upgrade to.
			def write_upgrade_body(protocol, body = nil)
				# Once we upgrade the connection, it can no longer handle other requests:
				@persistent = false
				
				write_upgrade_header(protocol)
				
				@stream.write("\r\n")
				@stream.flush # Don't remove me!
				
				if body
					body.each do |chunk|
						@stream.write(chunk)
						@stream.flush
					end
					
					@stream.close_write
				end
				
				return @stream
			ensure
				self.send_end_stream!
			end
			
			def write_tunnel_body(version, body = nil)
				@persistent = false
				
				write_connection_header(version)
				
				@stream.write("\r\n")
				@stream.flush # Don't remove me!
				
				if body
					body.each do |chunk|
						@stream.write(chunk)
						@stream.flush
					end
					
					@stream.close_write
				end
				
				return @stream
			ensure
				self.send_end_stream!
			end
			
			def write_empty_body(body)
				@stream.write("content-length: 0\r\n\r\n")
				@stream.flush
				
				body&.close
			ensure
				self.send_end_stream!
			end
			
			def write_fixed_length_body(body, length, head)
				@stream.write("content-length: #{length}\r\n\r\n")
				
				if head
					@stream.flush
					
					body.close
					
					return
				end
				
				@stream.flush unless body.ready?
				
				chunk_length = 0
				body.each do |chunk|
					chunk_length += chunk.bytesize
					
					if chunk_length > length
						raise ContentLengthError, "Trying to write #{chunk_length} bytes, but content length was #{length} bytes!"
					end
					
					@stream.write(chunk)
					@stream.flush unless body.ready?
				end
				
				@stream.flush
				
				if chunk_length != length
					raise ContentLengthError, "Wrote #{chunk_length} bytes, but content length was #{length} bytes!"
				end
			ensure
				self.send_end_stream!
			end
			
			def write_chunked_body(body, head, trailer = nil)
				@stream.write("transfer-encoding: chunked\r\n\r\n")
				
				if head
					@stream.flush
					
					body.close
					
					return
				end
				
				@stream.flush unless body.ready?
				
				body.each do |chunk|
					next if chunk.size == 0
					
					@stream.write("#{chunk.bytesize.to_s(16).upcase}\r\n")
					@stream.write(chunk)
					@stream.write(CRLF)
					
					@stream.flush unless body.ready?
				end
				
				if trailer&.any?
					@stream.write("0\r\n")
					write_headers(trailer)
					@stream.write("\r\n")
				else
					@stream.write("0\r\n\r\n")
				end
				
				@stream.flush
			ensure
				self.send_end_stream!
			end
			
			def write_body_and_close(body, head)
				# We can't be persistent because we don't know the data length:
				@persistent = false
				
				@stream.write("\r\n")
				@stream.flush unless body.ready?
				
				if head
					body.close
				else
					body.each do |chunk|
						@stream.write(chunk)
						
						@stream.flush unless body.ready?
					end
				end
				
				@stream.flush
				@stream.close_write
			ensure
				self.send_end_stream!
			end
			
			# The connection (stream) was closed. It may now be in the idle state.
			def closed(error = nil)
			end
			
			# Transition to the closed state.
			#
			# If no error occurred, and the connection is persistent, this will immediately transition to the idle state.
			#
			# @parameter error [Exxception] the error that caused the connection to close.
			def close!(error = nil)
				if @persistent and !error
					# If there was no error, and the connection is persistent, we can reuse it:
					@state = :idle
				else
					@state = :closed
				end
				
				self.closed(error)
			end
			
			def write_body(version, body, head = false, trailer = nil)
				# HTTP/1.0 cannot in any case handle trailers.
				if version == HTTP10 # or te: trailers was not present (strictly speaking not required.)
					trailer = nil
				end
				
				# While writing the body, we don't know if trailers will be added. We must choose a different body format depending on whether there is the chance of trailers, even if trailer.any? is currently false.
				#
				# Below you notice `and trailer.nil?`. I tried this but content-length is more important than trailers.
				
				if body.nil?
					write_connection_header(version)
					write_empty_body(body)
				elsif length = body.length # and trailer.nil?
					write_connection_header(version)
					write_fixed_length_body(body, length, head)
				elsif body.empty?
					# Even thought this code is the same as the first clause `body.nil?`, HEAD responses have an empty body but still carry a content length. `write_fixed_length_body` takes care of this appropriately.
					write_connection_header(version)
					write_empty_body(body)
				elsif version == HTTP11
					write_connection_header(version)
					# We specifically ensure that non-persistent connections do not use chunked response, so that hijacking works as expected.
					write_chunked_body(body, head, trailer)
				else
					@persistent = false
					write_connection_header(version)
					write_body_and_close(body, head)
				end
			end
			
			def receive_end_stream!
				if @state == :open
					@state = :half_closed_remote
				elsif @state == :half_closed_local
					self.close!
				else
					raise ProtocolError, "Cannot receive end stream in state: #{@state}!"
				end
			end
			
			def read_chunked_body(headers)
				Body::Chunked.new(self, headers)
			end
			
			def read_fixed_body(length)
				Body::Fixed.new(self, length)
			end
			
			def read_remainder_body
				@persistent = false
				Body::Remainder.new(self)
			end
			
			def read_head_body(length)
				# We are not receiving any body:
				self.receive_end_stream!
				
				Protocol::HTTP::Body::Head.new(length)
			end
			
			def read_tunnel_body
				read_remainder_body
			end
			
			def read_upgrade_body
				# When you have an incoming upgrade request body, we must be extremely careful not to start reading it until the upgrade has been confirmed, otherwise if the upgrade was rejected and we started forwarding the incoming request body, it would desynchronize the connection (potential security issue).
				# We mitigate this issue by setting @persistent to false, which will prevent the connection from being reused, even if the upgrade fails (potential performance issue).
				read_remainder_body
			end
			
			HEAD = "HEAD"
			CONNECT = "CONNECT"
			
			VALID_CONTENT_LENGTH = /\A\d+\z/
			
			def extract_content_length(headers)
				if content_length = headers.delete(CONTENT_LENGTH)
					if content_length =~ VALID_CONTENT_LENGTH
						yield Integer(content_length, 10)
					else
						raise BadRequest, "Invalid content length: #{content_length.inspect}"
					end
				end
			end
			
			def read_response_body(method, status, headers)
				# RFC 7230 3.3.3
				# 1.  Any response to a HEAD request and any response with a 1xx
				# (Informational), 204 (No Content), or 304 (Not Modified) status
				# code is always terminated by the first empty line after the
				# header fields, regardless of the header fields present in the
				# message, and thus cannot contain a message body.
				if method == HTTP::Methods::HEAD
					extract_content_length(headers) do |length|
						if length > 0
							return read_head_body(length)
						else
							return nil
						end
					end
					
					# There is no body for a HEAD request if there is no content length:
					return nil
				end
				
				if status == 101
					return read_upgrade_body
				end
				
				if (status >= 100 and status < 200) or status == 204 or status == 304
					return nil
				end
				
				# 2.  Any 2xx (Successful) response to a CONNECT request implies that
				# the connection will become a tunnel immediately after the empty
				# line that concludes the header fields.  A client MUST ignore any
				# Content-Length or Transfer-Encoding header fields received in
				# such a message.
				if method == HTTP::Methods::CONNECT and status == 200
					return read_tunnel_body
				end
				
				return read_body(headers, true)
			end
			
			def read_request_body(method, headers)
				# 2.  Any 2xx (Successful) response to a CONNECT request implies that
				# the connection will become a tunnel immediately after the empty
				# line that concludes the header fields.  A client MUST ignore any
				# Content-Length or Transfer-Encoding header fields received in
				# such a message.
				if method == HTTP::Methods::CONNECT
					return read_tunnel_body
				end
				
				# A successful upgrade response implies that the connection will become a tunnel immediately after the empty line that concludes the header fields.
				if headers[UPGRADE]
					return read_upgrade_body
				end
				
				# 6.  If this is a request message and none of the above are true, then
				# the message body length is zero (no message body is present).
				return read_body(headers)
			end
			
			def read_body(headers, remainder = false)
				# 3.  If a Transfer-Encoding header field is present and the chunked
				# transfer coding (Section 4.1) is the final encoding, the message
				# body length is determined by reading and decoding the chunked
				# data until the transfer coding indicates the data is complete.
				if transfer_encoding = headers.delete(TRANSFER_ENCODING)
					# If a message is received with both a Transfer-Encoding and a
					# Content-Length header field, the Transfer-Encoding overrides the
					# Content-Length.  Such a message might indicate an attempt to
					# perform request smuggling (Section 9.5) or response splitting
					# (Section 9.4) and ought to be handled as an error.  A sender MUST
					# remove the received Content-Length field prior to forwarding such
					# a message downstream.
					if headers[CONTENT_LENGTH]
						raise BadRequest, "Message contains both transfer encoding and content length!"
					end
					
					if transfer_encoding.last == CHUNKED
						return read_chunked_body(headers)
					else
						# If a Transfer-Encoding header field is present in a response and
						# the chunked transfer coding is not the final encoding, the
						# message body length is determined by reading the connection until
						# it is closed by the server.  If a Transfer-Encoding header field
						# is present in a request and the chunked transfer coding is not
						# the final encoding, the message body length cannot be determined
						# reliably; the server MUST respond with the 400 (Bad Request)
						# status code and then close the connection.
						return read_remainder_body
					end
				end
				
				# 5.  If a valid Content-Length header field is present without
				# Transfer-Encoding, its decimal value defines the expected message
				# body length in octets.  If the sender closes the connection or
				# the recipient times out before the indicated number of octets are
				# received, the recipient MUST consider the message to be
				# incomplete and close the connection.
				extract_content_length(headers) do |length|
					if length > 0
						return read_fixed_body(length)
					else
						return nil
					end
				end
				
				# http://tools.ietf.org/html/rfc2068#section-19.7.1.1
				if remainder
					# 7.  Otherwise, this is a response message without a declared message
					# body length, so the message body length is determined by the
					# number of octets received prior to the server closing the
					# connection.
					return read_remainder_body
				end
			end
		end
	end
end
