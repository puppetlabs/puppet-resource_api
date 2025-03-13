# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require_relative "string_buffer"

require_relative "shim/buffered"
require_relative "shim/readable"
require_relative "shim/timeout"

require_relative "openssl"

module IO::Stream
	# The default block size for IO buffers. Defaults to 64KB (typical pipe buffer size).
	BLOCK_SIZE = ENV.fetch("IO_STREAM_BLOCK_SIZE", 1024*64).to_i

	# The maximum read size when appending to IO buffers. Defaults to 8MB.
	MAXIMUM_READ_SIZE = ENV.fetch("IO_STREAM_MAXIMUM_READ_SIZE", BLOCK_SIZE * 128).to_i
	
	class LimitError < StandardError
	end
	
	class Generic
		def initialize(block_size: BLOCK_SIZE, maximum_read_size: MAXIMUM_READ_SIZE)
			@eof = false
			
			@writing = ::Thread::Mutex.new
			
			@block_size = block_size
			@maximum_read_size = maximum_read_size
			
			@read_buffer = StringBuffer.new
			@write_buffer = StringBuffer.new
			
			# Used as destination buffer for underlying reads.
			@input_buffer = StringBuffer.new
		end
		
		attr_accessor :block_size
		
		# Reads `size` bytes from the stream. If size is not specified, read until end of file.
		def read(size = nil)
			return String.new(encoding: Encoding::BINARY) if size == 0
			
			if size
				until @eof or @read_buffer.bytesize >= size
					# Compute the amount of data we need to read from the underlying stream:
					read_size = size - @read_buffer.bytesize
					
					# Don't read less than @block_size to avoid lots of small reads:
					fill_read_buffer(read_size > @block_size ? read_size : @block_size)
				end
			else
				until @eof
					fill_read_buffer
				end
			end
			
			return consume_read_buffer(size)
		end
		
		# Read at most `size` bytes from the stream. Will avoid reading from the underlying stream if possible.
		def read_partial(size = nil)
			return String.new(encoding: Encoding::BINARY) if size == 0
		
			if !@eof and @read_buffer.empty?
				fill_read_buffer
			end
			
			return consume_read_buffer(size)
		end
		
		def read_exactly(size, exception: EOFError)
			if buffer = read(size)
				if buffer.bytesize != size
					raise exception, "could not read enough data"
				end
				
				return buffer
			end
			
			raise exception, "encountered eof while reading data"
		end
		
		# This is a compatibility shim for existing code that uses `readpartial`.
		def readpartial(size = nil)
			read_partial(size) or raise EOFError, "Encountered eof while reading data!"
		end
		
		private def index_of(pattern, offset, limit)
			# We don't want to split on the pattern, so we subtract the size of the pattern.
			split_offset = pattern.bytesize - 1

			until index = @read_buffer.index(pattern, offset)
				offset = @read_buffer.bytesize - split_offset
				
				offset = 0 if offset < 0
				
				return nil if limit and offset >= limit
				return nil unless fill_read_buffer
			end
			
			return index
		end
		
		# Efficiently read data from the stream until encountering pattern.
		# @parameter pattern [String] The pattern to match.
		# @parameter offset [Integer] The offset to start searching from.
		# @parameter limit [Integer] The maximum number of bytes to read, including the pattern (even if chomped).
		# @returns [String | Nil] The contents of the stream up until the pattern, which is consumed but not returned.
		def read_until(pattern, offset = 0, limit: nil, chomp: true)
			if index = index_of(pattern, offset, limit)
				return nil if limit and index >= limit
				
				@read_buffer.freeze
				matched = @read_buffer.byteslice(0, index+(chomp ? 0 : pattern.bytesize))
				@read_buffer = @read_buffer.byteslice(index+pattern.bytesize, @read_buffer.bytesize)
				
				return matched
			end
		end
		
		def peek(size = nil)
			if size
				until @eof or @read_buffer.bytesize >= size
					# Compute the amount of data we need to read from the underlying stream:
					read_size = size - @read_buffer.bytesize
					
					# Don't read less than @block_size to avoid lots of small reads:
					fill_read_buffer(read_size > @block_size ? read_size : @block_size)
				end
				return @read_buffer[..([size, @read_buffer.size].min - 1)]
			end
			until (block_given? && yield(@read_buffer)) or @eof
				fill_read_buffer
			end
			return @read_buffer
		end
		
		def gets(separator = $/, limit = nil, chomp: false)
			# Compatibility with IO#gets:
			if separator.is_a?(Integer)
				limit = separator
				separator = $/
			end
			
			# We don't want to split in the middle of the separator, so we subtract the size of the separator from the start of the search:
			split_offset = separator.bytesize - 1
			
			offset = 0
			
			until index = @read_buffer.index(separator, offset)
				offset = @read_buffer.bytesize - split_offset
				offset = 0 if offset < 0
				
				# If a limit was given, and the offset is beyond the limit, we should return up to the limit:
				if limit and offset >= limit
					# As we didn't find the separator, there is nothing to chomp either.
					return consume_read_buffer(limit)
				end
				
				# If we can't read any more data, we should return what we have:
				return consume_read_buffer unless fill_read_buffer
			end
			
			# If the index of the separator was beyond the limit:
			if limit and index >= limit
				# Return up to the limit:
				return consume_read_buffer(limit)
			end
			
			# Freeze the read buffer, as this enables us to use byteslice without generating a hidden copy:
			@read_buffer.freeze
			
			line = @read_buffer.byteslice(0, index+(chomp ? 0 : separator.bytesize))
			@read_buffer = @read_buffer.byteslice(index+separator.bytesize, @read_buffer.bytesize)
			
			return line
		end
		
		private def drain(buffer)
			begin
				syswrite(buffer)
			ensure
				# If the write operation fails, we still need to clear this buffer, and the data is essentially lost.
				buffer.clear
			end
		end
		
		# Flushes buffered data to the stream.
		def flush
			return if @write_buffer.empty?
			
			@writing.synchronize do
				self.drain(@write_buffer)
			end
		end
		
		# Writes `string` to the buffer. When the buffer is full or #sync is true the
		# buffer is flushed to the underlying `io`.
		# @parameter string [String] the string to write to the buffer.
		# @returns [Integer] the number of bytes appended to the buffer.
		def write(string, flush: false)
			@writing.synchronize do
				@write_buffer << string
				
				flush |= (@write_buffer.bytesize >= @block_size)
				
				if flush
					self.drain(@write_buffer)
				end
			end
			
			return string.bytesize
		end
		
		# Writes `string` to the stream and returns self.
		def <<(string)
			write(string)
			
			return self
		end
		
		def puts(*arguments, separator: $/)
			return if arguments.empty?
			
			@writing.synchronize do
				arguments.each do |argument|
					@write_buffer << argument << separator
				end
				
				self.drain(@write_buffer)
			end
		end
		
		def closed?
			false
		end
		
		def close_read
		end
		
		def close_write
			flush
		end
		
		# Best effort to flush any unwritten data, and then close the underling IO.
		def close
			return if closed?
			
			begin
				flush
			rescue
				# We really can't do anything here unless we want #close to raise exceptions.
			ensure
				self.sysclose
			end
		end
		
		# Determins if the stream has consumed all available data. May block if the stream is not readable.
		# See {readable?} for a non-blocking alternative.
		#
		# @returns [Boolean] If the stream is at file which means there is no more data to be read.
		def eof?
			if !@read_buffer.empty?
				return false
			elsif @eof
				return true
			else
				return !self.fill_read_buffer
			end
		end
		
		def eof!
			@read_buffer.clear
			@eof = true
			
			raise EOFError
		end
		
		# Whether there is a chance that a read operation will succeed or not.
		# @returns [Boolean] If the stream is readable, i.e. a `read` operation has a chance of success.
		def readable?
			# If we are at the end of the file, we can't read any more data:
			if @eof
				return false
			end
			
			# If the read buffer is not empty, we can read more data:
			if !@read_buffer.empty?
				return true
			end
			
			# If the underlying stream is readable, we can read more data:
			return !closed?
		end
		
		protected
		
		def sysclose
			raise NotImplementedError
		end
		
		def syswrite(buffer)
			raise NotImplementedError
		end
		
		# Reads data from the underlying stream as efficiently as possible.
		def sysread(size, buffer)
			raise NotImplementedError
		end
		
		private
		
		# Fills the buffer from the underlying stream.
		def fill_read_buffer(size = @block_size)
			# We impose a limit because the underlying `read` system call can fail if we request too much data in one go.
			if size > @maximum_read_size
				size = @maximum_read_size
			end
			
			# This effectively ties the input and output stream together.
			flush
			
			if @read_buffer.empty?
				if sysread(size, @read_buffer)
					# Console.info(self, name: "read") {@read_buffer.inspect}
					return true
				end
			else
				if chunk = sysread(size, @input_buffer)
					@read_buffer << chunk
					# Console.info(self, name: "read") {@read_buffer.inspect}
					
					return true
				end
			end
			
			# else for both cases above:
			@eof = true
			return false
		end
		
		# Consumes at most `size` bytes from the buffer.
		# @parameter size [Integer|nil] The amount of data to consume. If nil, consume entire buffer.
		def consume_read_buffer(size = nil)
			# If we are at eof, and the read buffer is empty, we can't consume anything.
			return nil if @eof && @read_buffer.empty?
			
			result = nil
			
			if size.nil? or size >= @read_buffer.bytesize
				# Consume the entire read buffer:
				result = @read_buffer
				@read_buffer = StringBuffer.new
			else
				# This approach uses more memory.
				# result = @read_buffer.slice!(0, size)
				
				# We know that we are not going to reuse the original buffer.
				# But byteslice will generate a hidden copy. So let's freeze it first:
				@read_buffer.freeze
				
				result = @read_buffer.byteslice(0, size)
				@read_buffer = @read_buffer.byteslice(size, @read_buffer.bytesize)
			end
			
			return result
		end
	end
end
