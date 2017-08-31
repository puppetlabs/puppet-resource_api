require 'spec_helper'

RSpec.describe Puppet::ResourceApi do
  it 'has a version number' do
    expect(Puppet::ResourceApi::VERSION).not_to be nil
  end
end
