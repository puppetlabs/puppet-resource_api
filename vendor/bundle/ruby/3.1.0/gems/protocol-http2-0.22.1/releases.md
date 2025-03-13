# Releases

## v0.22.0

### Added Priority Update Frame and Stream Priority

HTTP/2 has deprecated the priority frame and stream dependency tracking. This feature has been effectively removed from the protocol. As a consequence, the internal implementation is greatly simplified. The `Protocol::HTTP2::Stream` class no longer tracks dependencies, and this includes `Stream#send_headers` which no longer takes `priority` as the first argument.

Optional per-request priority can be set using the `priority` header instead, and this value can be manipulated using the priority update frame.
