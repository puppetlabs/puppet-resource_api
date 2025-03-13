# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require_relative "stream/version"
require_relative "stream/buffered"

class IO
	module Stream
	end
	
	def self.Stream(io)
		if io.is_a?(Stream::Buffered)
			io
		else
			Stream::Buffered.wrap(io)
		end
	end
end
