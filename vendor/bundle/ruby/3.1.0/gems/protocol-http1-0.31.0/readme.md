# Protocol::HTTP1

Provides a low-level implementation of the HTTP/1 protocol.

[![Development Status](https://github.com/socketry/protocol-http1/workflows/Test/badge.svg)](https://github.com/socketry/protocol-http1/actions?workflow=Test)

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'protocol-http1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install protocol-http1

## Usage

Here is a basic HTTP/1.1 client:

``` ruby
require 'async'
require 'async/io/stream'
require 'async/http/endpoint'
require 'protocol/http1/connection'

Async do
	endpoint = Async::HTTP::Endpoint.parse("https://www.google.com/search?q=kittens", alpn_protocols: ["http/1.1"])
	
	peer = endpoint.connect
	
	puts "Connected to #{peer} #{peer.remote_address.inspect}"
	
	# IO Buffering...
	stream = Async::IO::Stream.new(peer)
	client = Protocol::HTTP1::Connection.new(stream)
	
	def client.read_line
		@stream.read_until(Protocol::HTTP1::Connection::CRLF) or raise EOFError
	end
	
	puts "Writing request..."
	client.write_request("www.google.com", "GET", "/search?q=kittens", "HTTP/1.1", [["Accept", "*/*"]])
	client.write_body(nil)
	
	puts "Reading response..."
	response = client.read_response("GET")
	
	puts "Got response: #{response.inspect}"
	
	puts "Closing client..."
	client.close
end
```

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
