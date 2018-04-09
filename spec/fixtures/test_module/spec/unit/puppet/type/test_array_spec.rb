require 'spec_helper'
require 'puppet/type/test_array'

RSpec.describe 'the test_array type' do
  it 'loads' do
    expect(Puppet::Type.type(:test_array)).not_to be_nil
  end
end
