# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

module Protocol
	module HTTP
		module Header
			# The `etag` header represents the entity tag for a resource.
			#
			# The `etag` header provides a unique identifier for a specific version of a resource, typically used for cache validation or conditional requests. It can be either a strong or weak validator as defined in RFC 9110.
			class ETag < String
				# Replaces the current value of the `etag` header with the specified value.
				#
				# @parameter value [String] the new value for the `etag` header.
				def << value
					replace(value)
				end
				
				# Checks whether the `etag` is a weak validator.
				#
				# Weak validators indicate semantically equivalent content but may not be byte-for-byte identical.
				#
				# @returns [Boolean] whether the `etag` is weak.
				def weak?
					self.start_with?("W/")
				end
			end
		end
	end
end
