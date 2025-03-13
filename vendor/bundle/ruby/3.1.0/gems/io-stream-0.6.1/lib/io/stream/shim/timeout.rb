# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

class IO
	unless const_defined?(:TimeoutError)
		# Compatibility shim.
		class TimeoutError < IOError
		end
	end
	
	unless method_defined?(:timeout)
		# Compatibility shim.
		attr_accessor :timeout
	end
end
