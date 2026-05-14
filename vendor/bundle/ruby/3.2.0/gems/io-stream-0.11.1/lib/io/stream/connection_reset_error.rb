# frozen_string_literal: true

module IO::Stream
	# Represents a connection reset error in IO streams, usually occurring when the remote side closes the connection unexpectedly.
	class ConnectionResetError < Errno::ECONNRESET
	end
end
