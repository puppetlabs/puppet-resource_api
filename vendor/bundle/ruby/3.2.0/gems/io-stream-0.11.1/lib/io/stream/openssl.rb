# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2025, by Samuel Williams.

require "openssl"

# @namespace
module OpenSSL
	# @namespace
	module SSL
		# SSL socket extensions for stream compatibility.
		class SSLSocket
			unless method_defined?(:close_read)
				# Close the read end of the SSL socket.
				def close_read
					# Ignored.
				end
			end
			
			unless method_defined?(:close_write)
				# Close the write end of the SSL socket.
				def close_write
					self.stop
				end
			end
			
			unless method_defined?(:wait_readable)
				# Wait for the SSL socket to become readable.
				def wait_readable(...)
					to_io.wait_readable(...)
				end
			end
			
			unless method_defined?(:wait_writable)
				# Wait for the SSL socket to become writable.
				def wait_writable(...)
					to_io.wait_writable(...)
				end
			end
			
			unless method_defined?(:timeout)
				# Get the timeout for SSL socket operations.
				# @returns [Numeric | Nil] The timeout value.
				def timeout
					to_io.timeout
				end
			end
			
			unless method_defined?(:timeout=)
				# Set the timeout for SSL socket operations.
				# @parameter value [Numeric | Nil] The timeout value.
				def timeout=(value)
					to_io.timeout = value
				end
			end
			
			unless method_defined?(:buffered?)
				# Check if the SSL socket is buffered.
				# @returns [Boolean] True if the SSL socket is buffered.
				def buffered?
					return to_io.buffered?
				end
			end
			
			unless method_defined?(:buffered=)
				# Set the buffered state of the SSL socket.
				# @parameter value [Boolean] True to enable buffering, false to disable.
				def buffered=(value)
					to_io.buffered = value
				end
			end
		end
	end
end
