# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

module IO::Stream
	class StringBuffer < String
		BINARY = Encoding::BINARY
		
		def initialize
			super
			
			force_encoding(BINARY)
		end
		
		def << string
			if string.encoding == BINARY
				super(string)
			else
				super(string.b)
			end
			
			return self
		end
		
		alias concat <<
	end
end
