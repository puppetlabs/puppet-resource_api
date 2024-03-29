# frozen_string_literal: true

require 'open3'
require 'spec_helper'
require 'tempfile'

RSpec.describe 'a type with composite namevars' do
  let(:common_args) { '--verbose --trace --debug --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet resource`' do
    it 'is returns the values correctly' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar")
      expect(stdout_str.strip).to match(/^composite_namevar/)
      expect(stdout_str.strip).to match(/Looking for nil/)
      expect(status).to eq 0
    end

    it 'returns the required resource correctly' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php-yum")
      expect(stdout_str.strip).to match(/^composite_namevar \{ 'php-yum'/)
      expect(stdout_str.strip).to match(/ensure\s*=> 'present'/)
      expect(stdout_str.strip).to match(/package\s*=> 'php'/)
      expect(stdout_str.strip).to match(/manager\s*=> 'yum'/)
      expect(stdout_str.strip).to match(/Looking for nil/)
      expect(status.exitstatus).to eq 0
    end

    it 'throws error if title is not a matching title_pattern' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php123 package=php manager=yum")
      expect(stdout_str.strip).to match(/No set of title patterns matched the title "php123"/)
      expect(stdout_str.strip).not_to match(/Looking for/)
      expect(status.exitstatus).to eq 1
    end

    it 'returns the match if alternative title_pattern matches' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php/gem")
      expect(stdout_str.strip).to match %r{^composite_namevar \{ 'php/gem'}
      expect(stdout_str.strip).to match(/ensure\s*=> 'present'/)
      # "Looking for" will return nil as puppet resource will have already fetched
      # the resource in instances():
      expect(stdout_str.strip).to match(/Looking for nil/)
      expect(status.exitstatus).to eq 0
    end

    it 'properly identifies an absent resource if only the title is provided' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php-wibble")
      expect(stdout_str.strip).to match(/^composite_namevar \{ 'php-wibble'/)
      expect(stdout_str.strip).to match(/ensure\s*=> 'absent'/)
      expect(stdout_str.strip).to match(/Looking for \[\{:package=>"php", :manager=>"wibble"\}\]/)
      expect(status.exitstatus).to eq 0
    end

    it 'creates a previously absent resource' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php-wibble ensure='present'")
      expect(stdout_str.strip).to match(/^composite_namevar \{ 'php-wibble'/)
      expect(stdout_str.strip).to match(/ensure\s*=> 'present'/)
      expect(stdout_str.strip).to match(/package\s*=> 'php'/)
      expect(stdout_str.strip).to match(/manager\s*=> 'wibble'/)
      expect(stdout_str.strip).to match(/Looking for \[\{:package=>"php", :manager=>"wibble"\}\]/)
      expect(status.exitstatus).to eq 0
    end

    it 'removes an existing resource' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php-gem ensure=absent")
      expect(stdout_str.strip).to match(/^composite_namevar \{ 'php-gem'/)
      expect(stdout_str.strip).to match(/package\s*=> 'php'/)
      expect(stdout_str.strip).to match(/manager\s*=> 'gem'/)
      expect(stdout_str.strip).to match(/ensure\s*=> 'absent'/)
      expect(stdout_str.strip).to match(/Looking for \[\{:package=>"php", :manager=>"gem"\}\]/)
      expect(status.exitstatus).to eq 0
    end
  end

  describe 'using `puppet apply`' do
    let(:common_args) { "#{super()} --detailed-exitcodes" }

    # run Open3.capture2e only once to get both output, and exitcode
    # rubocop:disable RSpec/InstanceVariable
    before do
      Tempfile.create('acceptance') do |f|
        f.write(manifest)
        f.close
        @stdout_str, @status = Open3.capture2e("puppet apply #{common_args} #{f.path}")
      end
    end

    context 'when matching title patterns' do
      context 'when managing a present instance' do
        let(:manifest) { 'composite_namevar { php-gem: }' }

        it { expect(@stdout_str).to match(/Current State: \{:title=>"php-gem", :package=>"php", :manager=>"gem", :ensure=>"present", :value=>"b"\}/) }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"gem"\}\]/) }
        it { expect(@status.exitstatus).to eq 0 }
      end

      context 'when managing an absent instance' do
        let(:manifest) { 'composite_namevar { php-wibble: ensure=>\'absent\' }' }

        it { expect(@stdout_str).to match(/Composite_namevar\[php-wibble\]: Nothing to manage: no ensure and the resource doesn't exist/) }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"wibble"\}\]/) }
        it { expect(@status.exitstatus).to eq 0 }
      end

      context 'when creating a previously absent instance' do
        let(:manifest) { 'composite_namevar { php-wibble: ensure=>\'present\' }' }

        it { expect(@stdout_str).to match %r{Composite_namevar\[php-wibble\]/ensure: defined 'ensure' as 'present'} }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"wibble"\}\]/) }
        it { expect(@status.exitstatus).to eq 2 }
      end

      context 'when removing a previously present instance' do
        let(:manifest) { 'composite_namevar { php-yum: ensure=>\'absent\' }' }

        it { expect(@stdout_str).to match %r{Composite_namevar\[php-yum\]/ensure: undefined 'ensure' from 'present'} }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"yum"\}\]/) }
        it { expect(@status.exitstatus).to eq 2 }
      end

      context 'when modifying an existing resource through an alternative title_pattern' do
        let(:manifest) { 'composite_namevar { \'php/gem\': value=>\'c\' }' }

        it { expect(@stdout_str).to match(/Current State: \{:title=>"php-gem", :package=>"php", :manager=>"gem", :ensure=>"present", :value=>"b"\}/) }
        it { expect(@stdout_str).to match(/Target State: \{:package=>"php", :manager=>"gem", :value=>"c", :ensure=>"present"\}/) }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"gem"\}\]/) }
        it { expect(@status.exitstatus).to eq 2 }
      end
    end

    context 'when using attributes' do
      context 'when managing a present instance' do
        let(:manifest) { 'composite_namevar { "sometitle": package => "php", manager => "gem" }' }

        it { expect(@stdout_str).to match(/Current State: \{:title=>"php-gem", :package=>"php", :manager=>"gem", :ensure=>"present", :value=>"b"\}/) }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"gem"\}\]/) }
        it { expect(@status.exitstatus).to eq 0 }
      end

      context 'when managing an absent instance' do
        let(:manifest) { 'composite_namevar { "sometitle": ensure => "absent", package => "php", manager => "wibble" }' }

        it { expect(@stdout_str).to match(/Composite_namevar\[sometitle\]: Nothing to manage: no ensure and the resource doesn't exist/) }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"wibble"\}\]/) }
        it { expect(@status.exitstatus).to eq 0 }
      end

      context 'when creating a previously absent instance' do
        let(:manifest) { 'composite_namevar { "sometitle": ensure => "present", package => "php", manager => "wibble" }' }

        it { expect(@stdout_str).to match %r{Composite_namevar\[sometitle\]/ensure: defined 'ensure' as 'present'} }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"wibble"\}\]/) }
        it { expect(@status.exitstatus).to eq 2 }
      end

      context 'when removing a previously present instance' do
        let(:manifest) { 'composite_namevar { "sometitle": ensure => "absent", package => "php", manager => "yum" }' }

        it { expect(@stdout_str).to match %r{Composite_namevar\[sometitle\]/ensure: undefined 'ensure' from 'present'} }
        it { expect(@stdout_str).to match(/Looking for \[\{:package=>"php", :manager=>"yum"\}\]/) }
        it { expect(@status.exitstatus).to eq 2 }
      end
    end
    # rubocop:enable RSpec/InstanceVariable
  end
end
