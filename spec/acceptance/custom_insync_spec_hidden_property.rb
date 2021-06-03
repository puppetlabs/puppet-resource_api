# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'a provider using custom insync' do
  subject(:stdout_str) do
    stdout_str, _status = Open3.capture2e("puppet apply --verbose --trace --strict=error --modulepath spec/fixtures -e \"#{manifest}\"")
    stdout_str
  end

  describe 'using `puppet apply`' do
    context 'when force is not specified' do
      let(:manifest) { 'test_custom_insync_hidden_property { example: }' }

      it 'calls insync? against rsapi_custom_insync_trigger, reporting no changes' do
        expect(stdout_str).not_to match %r{Setting with}
        expect(stdout_str).not_to match %r{Error:}
      end
    end

    context 'when force is specified as true' do
      let(:manifest) { 'test_custom_insync_hidden_property { example: force => true }' }

      it 'calls insync? against rsapi_custom_insync_trigger, reporting a change' do
        expect(stdout_str).to match %r{Out of sync!}
        expect(stdout_str).to match %r{Custom insync logic determined that this resource is out of sync}
        expect(stdout_str).to match %r{Setting with {:name=>"example", :force=>true}}
        expect(stdout_str).not_to match %r{Error:}
      end
    end
  end
end
