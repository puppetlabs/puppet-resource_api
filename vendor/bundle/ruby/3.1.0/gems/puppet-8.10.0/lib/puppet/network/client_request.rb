# frozen_string_literal: true

module Puppet::Network # :nodoc:
  # A struct-like class for passing around a client request.  It's mostly
  # just used for validation and authorization.
  class ClientRequest
    attr_accessor :name, :ip, :authenticated, :handler, :method

    def authenticated?
      authenticated
    end

    # A common way of talking about the full call.  Individual servers
    # are responsible for setting the values correctly, but this common
    # format makes it possible to check rights.
    def call
      raise ArgumentError, _("Request is not set up; cannot build call") unless handler and method

      [handler, method].join(".")
    end

    def initialize(name, ip, authenticated)
      @name = name
      @ip = ip
      @authenticated = authenticated
    end

    def to_s
      "#{name}(#{ip})"
    end
  end
end
