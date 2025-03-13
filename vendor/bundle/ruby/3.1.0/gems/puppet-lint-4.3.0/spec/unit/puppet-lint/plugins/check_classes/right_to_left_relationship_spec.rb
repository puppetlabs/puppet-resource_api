require 'spec_helper'

describe 'right_to_left_relationship' do
  let(:msg) { 'right-to-left (<-) relationship' }

  context 'chain 2 resources left to right' do
    let(:code) { 'Class[foo] -> Class[bar]' }

    it 'does not detect any problems' do
      expect(problems).to be_empty
    end
  end

  context 'chain 2 resources right to left' do
    let(:code) { 'Class[foo] <- Class[bar]' }

    it 'only detects a single problem' do
      expect(problems.size).to eq(1)
    end

    it 'creates a warning' do
      expect(problems).to contain_warning(msg).on_line(1).in_column(12)
    end
  end
end
