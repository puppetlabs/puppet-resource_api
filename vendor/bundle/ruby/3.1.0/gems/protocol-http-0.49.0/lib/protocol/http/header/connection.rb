# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2024, by Thomas Morgan.

require_relative "split"

module Protocol
	module HTTP
		module Header
			# Represents the `connection` HTTP header, which controls options for the current connection.
			#
			# The `connection` header is used to specify control options such as whether the connection should be kept alive, closed, or upgraded to a different protocol.
			class Connection < Split
				# The `keep-alive` directive indicates that the connection should remain open for future requests or responses, avoiding the overhead of opening a new connection.
				KEEP_ALIVE = "keep-alive"
				
				# The `close` directive indicates that the connection should be closed after the current request and response are complete.
				CLOSE = "close"
				
				# The `upgrade` directive indicates that the connection should be upgraded to a different protocol, as specified in the `Upgrade` header.
				UPGRADE = "upgrade"
				
				# Initializes the connection header with the given value. The value is expected to be a comma-separated string of directives.
				#
				# @parameter value [String | Nil] the raw `connection` header value.
				def initialize(value = nil)
					super(value&.downcase)
				end
				
				# Adds a directive to the `connection` header. The value will be normalized to lowercase before being added.
				#
				# @parameter value [String] the directive to add.
				def << value
					super(value.downcase)
				end
				
				# @returns [Boolean] whether the `keep-alive` directive is present and the connection is not marked for closure with the `close` directive.
				def keep_alive?
					self.include?(KEEP_ALIVE) && !close?
				end
				
				# @returns [Boolean] whether the `close` directive is present, indicating that the connection should be closed after the current request and response.
				def close?
					self.include?(CLOSE)
				end
				
				# @returns [Boolean] whether the `upgrade` directive is present, indicating that the connection should be upgraded to a different protocol.
				def upgrade?
					self.include?(UPGRADE)
				end
			end
		end
	end
end
