require 'spec_helper'
require 'puppet/type/test_validation'

RSpec.describe 'the test_validation type' do
  it 'loads' do
    expect(Puppet::Type.type(:test_validation)).not_to be_nil
  end
end
