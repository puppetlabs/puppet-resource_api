# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "openssl"

module OpenSSL
	module SSL
		class SSLSocket
			unless method_defined?(:close_read)
				def close_read
					# Ignored.
				end
			end
			
			unless method_defined?(:close_write)
				def close_write
					self.stop
				end
			end
			
			unless method_defined?(:wait_readable)
				def wait_readable(...)
					to_io.wait_readable(...)
				end
			end
			
			unless method_defined?(:wait_writable)
				def wait_writable(...)
					to_io.wait_writable(...)
				end
			end
			
			unless method_defined?(:timeout)
				def timeout
					to_io.timeout
				end
			end
			
			unless method_defined?(:timeout=)
				def timeout=(value)
					to_io.timeout = value
				end
			end
			
			unless method_defined?(:buffered?)
				def buffered?
					return to_io.buffered?
				end
			end
			
			unless method_defined?(:buffered=)
				def buffered=(value)
					to_io.buffered = value
				end
			end
		end
	end
end
