require 'spec_helper'

describe 'nested_classes_or_defines' do
  let(:class_msg) { 'class defined inside a class' }
  let(:define_msg) { 'defined type defined inside a class' }

  context 'class on its own' do
    let(:code) { 'class foo { }' }

    it 'does not detect any problems' do
      expect(problems).to be_empty
    end
  end

  context 'class inside a class' do
    let(:code) do
      <<-END
        class foo {
          class bar {
          }
        }
      END
    end

    it 'only detects a single problem' do
      expect(problems.size).to eq(1)
    end

    it 'creates a warning' do
      expect(problems).to contain_warning(class_msg).on_line(2).in_column(11)
    end
  end

  context 'instantiating a parametised class inside a class' do
    let(:code) do
      <<-END
        class bar {
          class { 'foo':
            bar => 'foobar'
          }
        }
      END
    end

    it 'does not detect any problems' do
      expect(problems).to be_empty
    end
  end

  context 'instantiating a parametised class inside a define' do
    let(:code) do
      <<-END
        define bar() {
          class { 'foo':
            bar => 'foobar'
          }
        }
      END
    end

    it 'does not detect any problems' do
      expect(problems).to be_empty
    end
  end

  context 'define inside a class' do
    let(:code) do
      <<-END
        class foo {
          define bar() {
          }
        }
      END
    end

    it 'only detects a single problem' do
      expect(problems.size).to eq(1)
    end

    it 'creates a warning' do
      expect(problems).to contain_warning(define_msg).on_line(2).in_column(11)
    end
  end
end
