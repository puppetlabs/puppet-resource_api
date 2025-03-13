require 'spec_helper'

describe 'space_before_arrow' do
  let(:msg) { "there should be a single space before '=>' on line %d, column %d" }

  context 'with code that should not trigger any warnings' do
    context 'resource with multiple parameters on different lines' do
      let(:code) do
        <<-END
          file { 'foo':
            foo => bar,
            bar  => buzz,
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'resource with single param and normal spacing' do
      let(:code) do
        <<-END
          file { 'foo':
            foo => bar,
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'resource with multiple params and normal spacing' do
      let(:code) do
        <<-END
          file { 'foo':
            foo => { "bar" => "baz" },
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end
  end

  context 'resource with a single param and simple value with too much space before arrow' do
    let(:code) do
      <<-END
        file { 'foo':
          foo  => bar,
        }
      END
    end

    context 'with fix disabled' do
      it 'detects extra space before arrow' do
        expect(problems.size).to eq(1)
      end

      it 'produces 1 warning' do
        expect(problems).to contain_warning(msg % [2, 14]).on_line(2).in_column(14)
      end
    end

    context 'with fix enabled' do
      before(:each) do
        PuppetLint.configuration.fix = true
      end

      after(:each) do
        PuppetLint.configuration.fix = false
      end

      it 'detects the problem' do
        expect(problems.size).to eq(1)
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg % [2, 14])
      end
    end
  end

  context 'resource with a single param, a hash as value and bad spacing within the hash' do
    let(:code) do
      <<-END
        file { 'foo':
          foo => { "bar"  => "baz" },
        }
      END
    end

    context 'with fix disabled' do
      it 'detects extra space before arrow' do
        expect(problems.size).to eq(1)
      end

      it 'produces a warning' do
        expect(problems).to contain_warning(msg % [2, 25]).on_line(2).in_column(25)
      end
    end

    context 'with fix enabled' do
      before(:each) do
        PuppetLint.configuration.fix = true
      end

      after(:each) do
        PuppetLint.configuration.fix = false
      end

      it 'detects the problem' do
        expect(problems.size).to eq(1)
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg % [2, 25])
      end
    end
  end
end
