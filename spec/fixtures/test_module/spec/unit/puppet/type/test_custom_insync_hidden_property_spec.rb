require 'spec_helper'
require 'puppet/type/test_custom_insync_hidden_property'

RSpec.describe 'the test_custom_insync_hidden_property type' do
  it 'loads' do
    expect(Puppet::Type.type(:test_custom_insync_hidden_property)).not_to be_nil
  end
end
