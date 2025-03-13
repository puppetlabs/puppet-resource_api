# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

module Protocol
	module HTTP2
		class Window
			# When an HTTP/2 connection is first established, new streams are created with an initial flow-control window size of 65,535 octets. The connection flow-control window is also 65,535 octets.
			DEFAULT_CAPACITY = 0xFFFF
			
			# @parameter capacity [Integer] The initial window size, typically from the settings.
			def initialize(capacity = DEFAULT_CAPACITY)
				# This is the main field required:
				@available = capacity
				
				# These two fields are primarily used for efficiently sending window updates:
				@used = 0
				@capacity = capacity
			end
			
			# The window is completely full?
			def full?
				@available <= 0
			end
			
			attr :used
			attr :capacity
			
			# When the value of SETTINGS_INITIAL_WINDOW_SIZE changes, a receiver MUST adjust the size of all stream flow-control windows that it maintains by the difference between the new value and the old value.
			def capacity= value
				difference = value - @capacity
				
				# An endpoint MUST treat a change to SETTINGS_INITIAL_WINDOW_SIZE that causes any flow-control window to exceed the maximum size as a connection error of type FLOW_CONTROL_ERROR.
				if (@available + difference) > MAXIMUM_ALLOWED_WINDOW_SIZE
					raise FlowControlError, "Changing window size by #{difference} caused overflow: #{@available + difference} > #{MAXIMUM_ALLOWED_WINDOW_SIZE}!"
				end
				
				@available += difference
				@capacity = value
			end
			
			def consume(amount)
				@available -= amount
				@used += amount
			end
			
			attr :available
			
			def available?
				@available > 0
			end
			
			def expand(amount)
				available = @available + amount
				
				if available > MAXIMUM_ALLOWED_WINDOW_SIZE
					raise FlowControlError, "Expanding window by #{amount} caused overflow: #{available} > #{MAXIMUM_ALLOWED_WINDOW_SIZE}!"
				end
				
				# puts "expand(#{amount}) @available=#{@available}"
				@available += amount
				@used -= amount
			end
			
			def wanted
				@used
			end
			
			def limited?
				@available < (@capacity / 2)
			end
			
			def inspect
				"\#<#{self.class} available=#{@available} used=#{@used} capacity=#{@capacity}#{limited? ? " limited" : nil}>"
			end
			
			alias to_s inspect
		end
		
		# This is a window which efficiently maintains a desired capacity.
		class LocalWindow < Window
			def initialize(capacity = DEFAULT_CAPACITY, desired: nil)
				super(capacity)
				
				# The desired capacity of the window, may be bigger than the initial capacity.
				# If that is the case, we will likely send a window update to the remote end to increase the capacity.
				@desired = desired
			end
			
			# The desired capacity of the window.
			attr_accessor :desired
			
			def wanted
				if @desired
					# We must send an update which allows at least @desired bytes to be sent.
					(@desired - @capacity) + @used
				else
					super
				end
			end
			
			def limited?
				if @desired
					# Do not send window updates until we are less than half the desired capacity:
					@available < (@desired / 2)
				else
					super
				end
			end
			
			def inspect
				"\#<#{self.class} available=#{@available} used=#{@used} capacity=#{@capacity} desired=#{@desired} #{limited? ? "limited" : nil}>"
			end
		end
	end
end
