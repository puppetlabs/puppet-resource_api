# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require_relative "generic"

module IO::Stream
	class Buffered < Generic
		def self.open(path, mode = "r+", **options)
			stream = self.new(::File.open(path, mode), **options)
			
			return stream unless block_given?
			
			begin
				yield stream
			ensure
				stream.close
			end
		end
		
		def self.wrap(io, **options)
			if io.respond_to?(:buffered=)
				io.buffered = false
			elsif io.respond_to?(:sync=)
				io.sync = true
			end
			
			stream = self.new(io, **options)
			
			return stream unless block_given?
			
			begin
				yield stream
			ensure
				stream.close
			end
		end
		
		def initialize(io, ...)
			super(...)
			
			@io = io
			if io.respond_to?(:timeout)
				@timeout = io.timeout
			else
				@timeout = nil
			end
		end
		
		attr :io
		
		def to_io
			@io.to_io
		end
		
		def closed?
			@io.closed?
		end
		
		def close_read
			@io.close_read
		end
		
		def close_write
			super
		ensure
			@io.close_write
		end
		
		def readable?
			super && @io.readable?
		end
		
		protected
		
		if RUBY_VERSION >= "3.3.0" and RUBY_VERSION < "3.3.6"
			def sysclose
				# https://bugs.ruby-lang.org/issues/20723
				Thread.new{@io.close}.join
			end
		else
			def sysclose
				@io.close
			end
		end
		
		def syswrite(buffer)
			# This fails due to re-entrancy issues with a concurrent call to `sysclose`.
			# return @io.write(buffer)
			
			while true
				result = @io.write_nonblock(buffer, exception: false)
				
				case result
				when :wait_readable
					@io.wait_readable(@io.timeout) or raise ::IO::TimeoutError, "read timeout"
				when :wait_writable
					@io.wait_writable(@io.timeout) or raise ::IO::TimeoutError, "write timeout"
				else
					if result == buffer.bytesize
						return
					else
						buffer = buffer.byteslice(result, buffer.bytesize)
					end
				end
			end
		end
		
		# Reads data from the underlying stream as efficiently as possible.
		def sysread(size, buffer)
			# Come on Ruby, why couldn't this just return `nil`? EOF is not exceptional. Every file has one.
			while true
				result = @io.read_nonblock(size, buffer, exception: false)
				
				case result
				when :wait_readable
					@io.wait_readable(@io.timeout) or raise ::IO::TimeoutError, "read timeout"
				when :wait_writable
					@io.wait_writable(@io.timeout) or raise ::IO::TimeoutError, "write timeout"
				else
					return result
				end
			end
		rescue Errno::EBADF
			raise ::IOError, "stream closed"
		end
	end
end
