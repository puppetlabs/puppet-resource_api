# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Puppet::ResourceApi::ProviderGetCache do
  subject(:cache) { described_class.new }

  before(:each) do
    cache.add(:a, 'a')
    cache.add(:b, 'b')
  end

  describe '#add/#get' do
    it 'sets and retrieves values from the cache' do
      expect(cache.get(:a)).to eq 'a'
    end
  end

  describe '#all' do
    it 'raises an error when cached_all has not been called' do
      expect { cache.all }.to raise_error(%r{cached_all not called})
    end

    it 'returns all values in cache when cached_all has been called' do
      cache.cached_all
      expect(cache.all).to eq %w[a b]
    end
  end

  describe '#cached_all?' do
    it 'returns false when cached_all has not been called' do
      expect(cache.cached_all?).to be false
    end

    it 'returns true when cached_all has been called' do
      cache.cached_all
      expect(cache.cached_all?).to be true
    end
  end

  describe '#clear' do
    it 'clears the cache' do
      cache.clear
      expect(cache.get(:a)).to be_nil
    end

    it 'resets the cached_all flag' do
      cache.cached_all
      cache.clear
      expect(cache.cached_all?).to be false
    end
  end
end
