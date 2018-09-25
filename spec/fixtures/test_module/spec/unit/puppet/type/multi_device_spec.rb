require 'spec_helper'
require 'puppet/type/multi_device'

RSpec.describe 'the multi_device type' do
  it 'loads' do
    expect(Puppet::Type.type(:multi_device)).not_to be_nil
  end
end
