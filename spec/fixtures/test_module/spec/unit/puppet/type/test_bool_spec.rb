require 'spec_helper'
require 'puppet/type/test_bool'

RSpec.describe 'the test_bool type' do
  it 'loads' do
    expect(Puppet::Type.type(:test_bool)).not_to be_nil
  end
end
