# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require_relative "stream/version"
require_relative "stream/buffered"

# @namespace
class IO
	# @namespace
	module Stream
	end
	
	# Convert any IO-like object into a buffered stream.
	# @parameter io [IO] The IO object to wrap.
	# @returns [IO::Stream::Buffered] A buffered stream wrapper.
	def self.Stream(io)
		if io.is_a?(Stream::Buffered)
			io
		else
			Stream::Buffered.wrap(io)
		end
	end
end
