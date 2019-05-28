require 'spec_helper'
require 'puppet/transport/schema/hue'

RSpec.describe 'the hue transport' do
  it 'loads' do
    expect(Puppet::ResourceApi::Transport.list['hue']).not_to be_nil
  end
end
