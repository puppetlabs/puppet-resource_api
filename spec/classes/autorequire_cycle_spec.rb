require 'spec_helper'

RSpec.describe 'test_module::autorequire_cycle' do
  context 'with make_cycle => false' do
    let(:params) { { make_cycle: false } }

    it { is_expected.to compile }
  end

  context 'with make_cycle => true' do
    let(:params) { { make_cycle: true } }

    it { is_expected.not_to compile }
  end
end
