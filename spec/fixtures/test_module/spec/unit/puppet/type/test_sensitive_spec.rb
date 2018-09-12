require 'spec_helper'
require 'puppet/type/test_sensitive'

RSpec.describe 'the test_sensitive type' do
  it 'loads' do
    expect(Puppet::Type.type(:test_sensitive)).not_to be_nil
  end
end
