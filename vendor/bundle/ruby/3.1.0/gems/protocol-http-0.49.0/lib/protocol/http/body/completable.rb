# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require_relative "wrapper"

module Protocol
	module HTTP
		module Body
			# Invokes a callback once the body has completed, either successfully or due to an error.
			class Completable < Wrapper
				# Wrap a message body with a callback. If the body is empty, the callback is invoked immediately.
				#
				# @parameter message [Request | Response] the message body.
				# @parameter block [Proc] the callback to invoke when the body is closed.
				def self.wrap(message, &block)
					if body = message&.body and !body.empty?
						message.body = self.new(message.body, block)
					else
						yield
					end
				end
				
				# Initialize the completable body with a callback.
				#
				# @parameter body [Readable] the body to wrap.
				# @parameter callback [Proc] the callback to invoke when the body is closed.
				def initialize(body, callback)
					super(body)
					
					@callback = callback
				end
				
				# @returns [Boolean] completable bodies are not rewindable.
				def rewindable?
					false
				end
				
				# Rewind the body, is not supported.
				def rewind
					false
				end
				
				# Close the body and invoke the callback. If an error is given, it is passed to the callback.
				#
				# The calback is only invoked once, and before `super` is invoked.
				def close(error = nil)
					if @callback
						@callback.call(error)
						@callback = nil
					end
					
					super
				end
			end
		end
	end
end
