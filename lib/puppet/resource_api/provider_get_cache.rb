# frozen_string_literal: true

# rubocop:disable Style/Documentation
module Puppet; end
module Puppet::ResourceApi; end
# rubocop:enable Style/Documentation

# This class provides a simple caching mechanism to support minimizing get()
# calls into a provider.
class Puppet::ResourceApi::ProviderGetCache
  def initialize
    clear
  end

  def clear
    @cache = {}
    @cached_all = false
  end

  def all
    raise 'all method called, but cached_all not called' unless @cached_all

    @cache.values
  end

  def add(key, value)
    @cache[key] = value
  end

  def get(key)
    @cache[key]
  end

  def cached_all
    @cached_all = true
  end

  def cached_all?
    @cached_all
  end
end
