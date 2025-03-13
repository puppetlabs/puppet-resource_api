# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2024, by Samuel Williams.

module Metrics
	module Tags
		def self.normalize(tags)
			return nil unless tags&.any?
			
			if tags.is_a?(Hash)
				tags = tags.map{|key, value| "#{key}:#{value}"}
			end
			
			return Array(tags)
		end
	end
end
