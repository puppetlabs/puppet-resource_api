# IO::Stream

Provide a buffered stream implementation for Ruby, independent of the underlying IO.

[![Development Status](https://github.com/socketry/io-stream/workflows/Test/badge.svg)](https://github.com/socketry/io-stream/actions?workflow=Test)

## Usage

Please see the [project documentation](https://socketry.github.io/io-stream) for more details.

## Releases

Please see the [project releases](https://socketry.github.io/io-streamreleases/index) for all releases.

### v0.11.0

  - Introduce `class IO::Stream::ConnectionResetError < Errno::ECONNRESET` to standardize connection reset error handling across different IO types.
      - `OpenSSL::SSL::SSLSocket` raises `OpenSSL::SSL::SSLError` on connection reset, while other IO types raise `Errno::ECONNRESET`. `SSLError` is now rescued and re-raised as `IO::Stream::ConnectionResetError` for consistency.

### v0.10.0

  - Rename `done?` to `finished?` for clarity and consistency.

### v0.9.1

  - Fix EOF behavior to match Ruby IO semantics: `read()` returns empty string `""` at EOF while `read(size)` returns `nil` at EOF.

### v0.9.0

  - Add support for `buffer` parameter in `read`, `read_exactly`, and `read_partial` methods to allow reading into a provided buffer.

### v0.8.0

  - On Ruby v3.3+, use `IO#write` directly instead of `IO#write_nonblock`, for better performance.
  - Introduce support for `Readable#discard_until` method to discard data until a specific pattern is found.

### v0.7.0

  - Split stream functionality into separate `Readable` and `Writable` modules for better modularity and composition.
  - Remove unused timeout shim functionality.
  - 100% documentation coverage.

### v0.6.1

  - Fix compatibility with Ruby v3.3.0 - v3.3.6 where broken `@io.close` could hang.

### v0.6.0

  - Improve compatibility of `gets` implementation to better match Ruby's IO\#gets behavior.

### v0.5.0

  - Add support for `read_until(limit:)` parameter to limit the amount of data read.
  - Minor documentation improvements.

### v0.4.3

  - Add comprehensive tests for `buffered?` method on `SSLSocket`.
  - Ensure TLS connections have correct buffering behavior.
  - Improve test suite organization and readability.

## See Also

  - [async-io](https://github.com/socketry/async-io) — Where this implementation originally came from.

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
