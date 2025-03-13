require 'spec_helper'

describe 'top_scope_facts' do
  let(:msg) { 'top scope fact instead of facts hash' }

  context 'with fix disabled' do
    context 'fact variable using $facts hash' do
      let(:code) { "$facts['operatingsystem']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'non-fact variable with two colons' do
      let(:code) { '$foo::bar' }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'top scope $::facts hash' do
      let(:code) { "$::facts['os']['family']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'top scope $::trusted hash' do
      let(:code) { "$::trusted['certname']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'fact variable using top scope' do
      let(:code) { '$::fqdn' }

      it 'does not detect a single problem' do
        expect(problems).to be_empty
      end
    end

    context 'out of scope namespaced variable with leading ::' do
      let(:code) { '$::profile::foo::bar' }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end

      context 'inside double quotes' do
        let(:code) { '"$::profile::foo::bar"' }

        it 'does not detect any problems' do
          expect(problems).to be_empty
        end
      end

      context 'with curly braces in double quote' do
        let(:code) { '"${::profile::foo::bar}"' }

        it 'does not detect any problems' do
          expect(problems).to be_empty
        end
      end
    end
  end

  context 'with fix enabled' do
    before(:each) do
      PuppetLint.configuration.fix = true
    end

    after(:each) do
      PuppetLint.configuration.fix = false
    end

    context 'fact variable using $facts hash' do
      let(:code) { "$facts['operatingsystem']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'non-fact variable with two colons' do
      let(:code) { '$foo::bar' }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'top scope $::facts hash' do
      let(:code) { "$::facts['os']['family']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'top scope structured fact not present on allowlist' do
      let(:code) { "$::my_structured_fact['foo']['test']" }

      it 'detects a problem' do
        expect(problems).to contain_fixed('top scope fact instead of facts hash').on_line(1).in_column(1)
      end

      it 'fixes the problem' do
        expect(manifest).to eq("$facts['my_structured_fact']['foo']['test']")
      end
    end

    context 'top scope $::trusted hash' do
      let(:code) { "$::trusted['certname']" }

      it 'does not detect any problems' do
        expect(problems).to be_empty
      end
    end

    context 'with custom top scope fact variables' do
      before(:each) do
        PuppetLint.configuration.top_scope_variables = ['location', 'role']
      end

      context 'fact variable using $facts hash' do
        let(:code) { "$facts['operatingsystem']" }

        it 'does not detect any problems' do
          expect(problems).to be_empty
        end
      end

      context 'fact variable using $trusted hash' do
        let(:code) { "$trusted['certname']" }

        it 'does not detect any problems' do
          expect(problems).to be_empty
        end
      end

      context 'allowlisted top scope variable $::location' do
        let(:code) { '$::location' }

        it 'does not detect any problems' do
          expect(problems).to be_empty
        end
      end

      context 'non-allowlisted top scope variable $::application' do
        let(:code) { '$::application' }

        it 'detects a problem' do
          expect(problems).to contain_fixed('top scope fact instead of facts hash').on_line(1).in_column(1)
        end
      end
    end
  end
end
