require 'spec_helper'

RSpec.describe Puppet::ResourceApi::BaseContext do
  class TestContext < described_class
    attr_reader :last_level, :last_message
    def send_log(l, m)
      @last_level = l
      @last_message = m
    end
  end

  subject(:context) do
    TestContext.new('some_resource')
  end

  describe '#config' do
    context 'when a NetworkDevice is configured' do
      let(:device) { instance_double('Puppet::Util::NetworkDevice::Simple::Device', 'device') }

      before(:each) do
        allow(Puppet::Util::NetworkDevice).to receive(:current).and_return(device)
        allow(device).to receive(:config).and_return({ 'foo' => 'bar' })
      end

      it 'returns the device\'s config' do
        expect(context.config).to eq({ 'foo' => 'bar' })
      end
    end
    context 'with no NetworkDevice configured' do
      before(:each) do
        allow(Puppet::Util::NetworkDevice).to receive(:current).and_return(nil)
      end
      it 'raises an error' do
        expect { context.config }.to raise_error RuntimeError, %r{no device configured}
      end
    end
  end

  describe '#warning(msg)' do
    it 'outputs the message' do
      context.warning('message')
      expect(context.last_message).to eq 'some_resource: message'
    end
    it 'outputs at the correct level' do
      context.warning('message')
      expect(context.last_level).to eq :warning
    end
  end

  describe '#warning(titles, msg)' do
    it 'formats no titles correctly' do
      context.warning([], 'message')
      expect(context.last_message).to eq 'some_resource: message'
    end
    it 'formats an empty title correctly' do
      context.warning('', 'message')
      expect(context.last_message).to eq 'some_resource[]: message'
    end
    it 'formats a single title' do
      context.warning('a', 'message')
      expect(context.last_message).to eq 'some_resource[a]: message'
    end
    it 'formats multiple titles' do
      context.warning(%w[a b], 'message')
      expect(context.last_message).to eq 'some_resource[a, b]: message'
    end
  end
  describe '#warning(msg1, msg2, msg3, ...)' do
    it 'outputs all passed messages' do
      context.warning('msg1', 'msg2', 'msg3')
      expect(context.last_message).to eq 'msg1, msg2, msg3'
    end
  end

  [:creating, :updating, :deleting].each do |method|
    describe "##{method}(title, &block)" do
      it 'outputs the start and stop messages' do
        allow(context).to receive(:send_log)
        expect(context).to receive(:send_log).with(:debug, %r{some_title.*#{method.to_s}.*start}i)
        expect(context).to receive(:send_log).with(:notice, %r{some_title.*#{method.to_s}.*finished}i)
        context.send(method, 'some_title') {}
      end

      it 'logs completion time' do
        allow(context).to receive(:send_log).with(:debug, anything)
        expect(context).to receive(:send_log).with(:notice, %r{finished in [0-9]*\.[0-9]* seconds}i)
        context.send(method, 'timed_resource') {}
      end

      it 'does not leak state between invocations' do
        context.send(method, 'resource_one') {}
        expect(context).to receive(:send_log).with(:debug, %r{resource_two.*#{method.to_s}.*start}i)
        expect(context).not_to receive(:send_log).with(anything, %r{.*resource_one.*})
        context.send(method, 'resource_two') {}
      end

      context 'when a StandardError is raised' do
        it 'swallows the exception' do
          pending('Currently the error is raised, when it should be swallowed')
          expect {
            context.send(method, 'bad_resource') { raise StandardError, 'Bad Resource!' }
          }.not_to raise_error
        end

        it 'logs an error' do
          pending('Currently the error is raised, when it should be swallowed')
          allow(context).to receive(:send_log)
          expect(context).to receive(:send_log).with(:err, %r{bad_resource.*#{method.to_s}.*failed.*reasons}i)
          context.send(method, 'bad_resource') { raise StandardError, 'Reasons' }
        end

        it 'does not leak state into next invocation' do
          pending('Currently the error is raised, when it should be swallowed')
          context.send(method, 'resource_one') { raise StandardError, 'Bad Resource!' }
          expect(context).to receive(:send_log).with(:debug, %r{resource_two.*#{method.to_s}.*start}i)
          expect(context).not_to receive(:send_log).with(anything, %r{.*resource_one.*})
          context.send(method, 'resource_two') {}
        end
      end

      context 'when an Exception that is not StandardError is raised' do
        it 'raises the exception' do
          expect {
            context.send(method, 'total_failure') { raise LoadError, 'Disk Read Error' }
          }.to raise_error(LoadError, 'Disk Read Error')
        end

        it 'does not leak state into next invocation' do
          expect {
            context.send(method, 'resource_one') { raise LoadError, 'Uh oh' }
          }.to raise_error(LoadError, 'Uh oh')
          expect(context).to receive(:send_log).with(:debug, %r{resource_two.*#{method.to_s}.*start}i)
          expect(context).not_to receive(:send_log).with(anything, %r{.*resource_one.*})
          context.send(method, 'resource_two') {}
        end
      end
    end
  end

  describe '#failing(titles, &block)' do
    it 'logs a debug start message' do
      allow(context).to receive(:send_log)
      expect(context).to receive(:send_log).with(:debug, %r{\[Thing\[one\], Thing\[two\]\].*failing.*start}i)
      context.failing(['Thing[one]', 'Thing[two]']) {}
    end

    it 'logs a warning on completion' do
      allow(context).to receive(:send_log)
      expect(context).to receive(:send_log).with(:warning, %r{\[Thing\[one\], Thing\[two\]\].*failing.*finished}i)
      context.failing(['Thing[one]', 'Thing[two]']) {}
    end

    it 'logs completion time' do
      allow(context).to receive(:send_log)
      expect(context).to receive(:send_log).with(:warning, %r{finished failing in [0-9]*\.[0-9]* seconds}i)
      context.failing(['Thing[one]', 'Thing[two]']) {}
    end

    it 'does not leak state between invocations' do
      context.failing('resource_one') {}
      expect(context).to receive(:send_log).with(:debug, %r{resource_two.*failing.*start}i)
      expect(context).not_to receive(:send_log).with(anything, %r{.*resource_one.*})
      context.failing('resource_two') {}
    end

    context 'when a StandardError is raised' do
      it 'swallows the exception' do
        pending('Currently the error is raised, when it should be swallowed')
        expect {
          context.failing('bad_resource') { raise StandardError, 'Bad Resource!' }
        }.not_to raise_error
      end

      it 'logs an error' do
        pending('Currently the error is raised, when it should be swallowed')
        allow(context).to receive(:send_log)
        expect(context).to receive(:send_log).with(:err, %r{bad_resource.*failing.*failed.*reasons}i)
        context.failing('bad_resource') { raise StandardError, 'Reasons' }
      end

      it 'does not leak state into next invocation' do
        pending('Currently the error is raised, when it should be swallowed')
        context.failing('resource_one') { raise StandardError, 'Bad Resource!' }
        expect(context).to receive(:send_log).with(:debug, %r{resource_two.*failing.*start}i)
        expect(context).not_to receive(:send_log).with(anything, %r{.*resource_one.*})
        context.failing('resource_two') {}
      end
    end

    context 'when an Exception that is not StandardError is raised' do
      it 'raises the exception' do
        expect {
          context.failing('total_failure') { raise LoadError, 'Disk Read Error' }
        }.to raise_error(LoadError, 'Disk Read Error')
      end

      it 'does not leak state into next invocation' do
        expect {
          context.failing('resource_one') { raise LoadError, 'Uh oh' }
        }.to raise_error(LoadError, 'Uh oh')
        expect(context).to receive(:send_log).with(:debug, %r{resource_two.*failing.*start}i)
        expect(context).not_to receive(:send_log).with(anything, %r{.*resource_one.*})
        context.failing('resource_two') {}
      end
    end
  end

  [:created, :updated, :deleted].each do |method|
    describe "##{method}(titles, message: '#{method.to_s.capitalize}')" do
      it 'logs the action at :notice level' do
        expect(context).to receive(:send_log).with(:notice, %r{#{method.to_s.capitalize}: \[\"Thing\[one\]\", \"Thing\[two\]\"\]}i)
        context.send(method, ['Thing[one]', 'Thing[two]'])
      end

      it 'logs a custom message if provided' do
        expect(context).to receive(:send_log).with(:notice, %r{My provider did the action: \[\"Thing\[one\]\", \"Thing\[two\]\"\]}i)
        context.send(method, ['Thing[one]', 'Thing[two]'], message: 'My provider did the action')
      end
    end
  end

  describe '#failed(titles, message: \'Failed\')' do
    it 'logs the action at :err level' do
      expect(context).to receive(:send_log).with(:err, %r{\[Thing\[one\], Thing\[two\]\].*failed})
      context.failed(['Thing[one]', 'Thing[two]'])
    end

    it 'logs a custom message if provided' do
      expect(context).to receive(:send_log).with(:err, %r{\[Thing\[one\], Thing\[two\]\].*My provider is really sorry})
      context.failed(['Thing[one]', 'Thing[two]'], message: 'My provider is really sorry')
    end
  end

  describe '#processed(title, is, should)' do
    it 'logs the successful change of attributes' do
      expect(context).to receive(:send_log).with(:notice, %r{Processed Thing\[one\] from {:ensure=>:absent} to {:ensure=>:present, :name=>\"thing one\"}})
      context.processed('Thing[one]', { ensure: :absent }, { ensure: :present, name: 'thing one' })
    end

    it 'raises if multiple titles are passed' do
      expect { context.processed(['Thing[one]', 'Thing[two'], { foo: 'bar' }, { foo: 'baz' })  }.to raise_error('processed only accepts a single resource title')
    end
  end

  describe '#processing(title, is, should, message: \'Processing\', &block)' do
    it 'raises if multiple titles are passed' do
      expect { context.processing(['Thing[one]', 'Thing[two'], { foo: 'bar' }, { foo: 'baz' }) { puts 'Doing it' } }.to raise_error('processing only accepts a single resource title')
    end

    it 'logs the start message' do
      allow(context).to receive(:send_log)
      expect(context).to receive(:send_log).with(:debug, %r{starting processing of.*some_title.*}i)
      context.processing('some_title', { ensure: 'absent' }, { name: 'some_title', ensure: 'present' }) {}
    end

    it 'logs a succesful change' do
      allow(context).to receive(:send_log)
      expect(context).to receive(:send_log).with(:notice, %r{Finished processing some_title in .* seconds: \{:name=>\"some_title\", :ensure=>\"present\"\}}i)
      context.processing('some_title', { ensure: 'absent' }, { name: 'some_title', ensure: 'present' }) {}
    end

    it 'logs completion time' do
      allow(context).to receive(:send_log).with(:debug, anything)
      expect(context).to receive(:send_log).with(:notice, %r{finished processing some_title in [0-9]*\.[0-9]* seconds}i)
      context.processing('some_title', { ensure: 'absent' }, ensure: 'present') {}
    end

    it 'logs failure if the block raises an exception' do
      allow(context).to receive(:send_log).with(:debug, anything)
      expect(context).to receive(:send_log).with(:err, %r{failed processing some_title after [0-9]*\.[0-9]* seconds: salt the fries}i)
      expect { context.processing('some_title', { ensure: 'absent' }, ensure: 'present') { raise StandardError, 'salt the fries' } }.to raise_error(StandardError)
    end

    it 'does not leak state between invocations' do
      context.processing('resource_one', { ensure: 'absent' }, ensure: 'present') {}
      expect(context).to receive(:send_log).with(:debug, %r{processing of resource_two}i)
      expect(context).not_to receive(:send_log).with(anything, %r{.*resource_one.*})
      context.processing('resource_two', { ensure: 'absent' }, ensure: 'present') {}
    end
  end

  describe 'attribute_changed(title, attribute, is, should, message: nil)' do
    it 'logs string values with quotes' do
      expect(context).to receive(:send_log).with(:notice, %r{Thing\[foo\]: attribute 'config_file' changed from '/tmp/foo.cfg' to '/tmp/bar.cfg'}i)
      context.attribute_changed('Thing[foo]', 'config_file', '/tmp/foo.cfg', '/tmp/bar.cfg')
    end

    it 'logs number values without quotes' do
      expect(context).to receive(:send_log).with(:notice, %r{attribute 'height' changed from 5 to 6$}i)
      context.attribute_changed('Thing[foo]', 'height', 5, 6)
    end

    it 'logs a nil should value as \'nil\'' do
      expect(context).to receive(:send_log).with(:notice, %r{attribute 'height' changed from 5 to nil$}i)
      context.attribute_changed('Thing[foo]', 'height', 5, nil)
    end

    it 'logs a nil is value as \'nil\'' do
      expect(context).to receive(:send_log).with(:notice, %r{attribute 'height' changed from nil to 6$}i)
      context.attribute_changed('Thing[foo]', 'height', nil, 6)
    end

    it 'logs with a message if one is passed' do
      expect(context).to receive(:send_log).with(:notice, %r{attribute 'height' changed from 5 to 6: something interesting$}i)
      context.attribute_changed('Thing[foo]', 'height', 5, 6, message: 'something interesting')
    end

    it 'raises if multiple titles are passed' do
      expect { context.attribute_changed(['Thing[one]', 'Thing[two]'], 'room', 'clean', 'messy') }.to raise_error('attribute_changed only accepts a single resource title')
    end
  end

  describe '#format_seconds' do
    it 'returns 6 decimal points for a number less than 1' do
      expect(described_class.new('short_time').send(:format_seconds, 0.000136696)).to eq('0.000137')
    end

    it 'returns 2 decimal places for a number greater than 1' do
      expect(described_class.new('long_time').send(:format_seconds, 123.45678)).to eq('123.46')
      expect(described_class.new('longer_time').send(:format_seconds, 1_234_567.89)).to eq('1234567.89')
      expect(described_class.new('exact_time').send(:format_seconds, 123_456)).to eq('123456.00')
    end
  end

  describe '#send_log' do
    it { expect { described_class.new(nil).send_log(nil, nil) }.to raise_error RuntimeError, %r{Received send_log\(\) on an unprepared BaseContext\. Use IOContext, or PuppetContext instead} }
  end
end
