require 'spec_helper'
require 'tempfile'

RSpec.describe 'calling a Command' do
  let(:touch_cmd) { Puppet::ResourceApi::Command.new('touch') }
  let(:tee_cmd) { Puppet::ResourceApi::Command.new('tee') }
  let(:context) { instance_double('Puppet::ResourceApi::BaseContext') }

  describe '#run(context, *args, **kwargs)' do
    it 'executes a command' do
      File.delete '/tmp/söme_file' if File.exist? '/tmp/söme_file'
      touch_cmd.run(context, '/tmp/söme_file')
      expect(File).to be_exist('/tmp/söme_file')
    end

    it 'doesn\'t provide input to a command' do
      output = Tempfile.new('input-none')
      begin
        tee_cmd.run(context, output.path, stdin_source: :none)
        expect(File.size(output.path)).to be_zero
      ensure
        output.close
        output.unlink
      end
    end

    describe 'stdin_source: :value' do
      before(:each) do
        allow(context).to receive(:debug)
      end

      it 'provides the specified value as input to the process' do
        output = Tempfile.new('input-value')
        begin
          tee_cmd.run(context, output.path, stdin_source: :value, stdin_value: 'föö')
          expect(IO.read(output.path)).to eq 'föö'
        ensure
          output.close
          output.unlink
        end
      end
    end
  end
end
