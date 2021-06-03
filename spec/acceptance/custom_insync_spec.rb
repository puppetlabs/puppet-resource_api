# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'a provider using custom insync' do
  describe 'using `puppet apply`' do
    subject(:puppet_apply_stdout) do
      stdout_str, _status = Open3.capture2e("puppet apply --verbose --trace --strict=error --modulepath spec/fixtures -e \"#{manifest}\"")
      stdout_str
    end

    context 'when an error is raised during insync?' do
      let(:raising_resource_declaration) { "test_custom_insync { example: ensure => 'present', case_insensitive_string => 'RaiseError' }" }
      let(:manifest) { raising_resource_declaration.dup }

      it 'reports the error with stack trace and change failure' do
        expect(puppet_apply_stdout).to match %r{Error:}
        expect(puppet_apply_stdout).to match %r{block in def_custom_insync?}
        expect(puppet_apply_stdout).to match %r{change from 'FooBar' to 'RaiseError' failed}
      end

      context 'with a dependent resource' do
        let(:dependent_resource_declaration) do
          "test_custom_insync { dependent: ensure => 'present', case_insensitive_string => 'foobar', require => Test_custom_insync['example'] }"
        end
        let(:manifest) { "#{raising_resource_declaration} #{dependent_resource_declaration}" }

        it 'skips dependent resource because of failed dependencies' do
          expect(puppet_apply_stdout).to match %r{Test_custom_insync\[dependent\]: Skipping because of failed dependencies}
        end
      end
    end

    context 'when handling subset array comparisons' do
      let(:manifest) { "test_custom_insync { example: ensure => 'present', some_array => #{test_value} }" }

      context 'when the should array is an exact match for the actual value' do
        let(:test_value) { %w[a b] }

        it 'makes no changes and does not error' do
          expect(puppet_apply_stdout).not_to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end

      context 'when the should array members are all included in the actual value' do
        let(:test_value) { ['a'] }

        it 'makes no changes and does not error' do
          expect(puppet_apply_stdout).not_to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end

      context 'when the the actual value is missing a should array member' do
        let(:test_value) { %w[a b c] }

        it 'makes no changes and does not error' do
          expect(puppet_apply_stdout).to match %r{Adding missing members \["c"\]}
          expect(puppet_apply_stdout).to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end
    end

    context 'when handling forced array comparisons' do
      let(:manifest) { "test_custom_insync { example: ensure => 'present', some_array => #{test_value}, force => true }" }

      context 'when the should array is an exact match for the actual value' do
        let(:test_value) { %w[a b] }

        it 'makes no changes and does not error' do
          expect(puppet_apply_stdout).not_to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end

      context 'when the should array is an order insensitive match for the actual value' do
        let(:test_value) { %w[b a] }

        it 'makes no changes and does not error' do
          expect(puppet_apply_stdout).not_to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end

      context 'when the actual value includes members not found in the should array' do
        let(:test_value) { ['a'] }

        it 'removes the additional member from the array without erroring' do
          expect(puppet_apply_stdout).to match %r{some_array changed \['a', 'b'\] to \['a'\]}
          expect(puppet_apply_stdout).to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end

      context 'when the the actual value is missing a should array member' do
        let(:test_value) { %w[a b c] }

        it 'adds the missing member to the array without erroring' do
          expect(puppet_apply_stdout).to match %r{some_array changed \['a', 'b'\] to \['a', 'b', 'c'\]}
          expect(puppet_apply_stdout).to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end
    end

    context 'when handling case sensitive string comparisons' do
      let(:manifest) { "test_custom_insync { example: ensure => 'present', case_sensitive_string => '#{test_value}' }" }

      context 'when the strings match exactly' do
        let(:test_value) { 'FooBar' }

        it 'makes no changes and does not error' do
          expect(puppet_apply_stdout).not_to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end

      context 'when the strings differ' do
        let(:test_value) { 'foobar' }

        it 'changes the string value without erroring' do
          expect(puppet_apply_stdout).to match %r{case_sensitive_string changed 'FooBar' to 'foobar'}
          expect(puppet_apply_stdout).to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end
    end

    context 'when handling case insensitive string comparisons' do
      let(:manifest) { "test_custom_insync { example: ensure => 'present', case_insensitive_string => '#{test_value}' }" }

      context 'when the strings match exactly' do
        let(:test_value) { 'FooBar' }

        it 'makes no changes and does not error' do
          expect(puppet_apply_stdout).not_to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end

      context 'when the strings match exactly except for casing' do
        let(:test_value) { 'foobar' }

        it 'makes no changes and does not error' do
          expect(puppet_apply_stdout).not_to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end

      context 'when the strings differ' do
        let(:test_value) { 'FooBarBaz' }

        it 'changes the string value without erroring' do
          expect(puppet_apply_stdout).to match %r{case_insensitive_string changed 'FooBar' to 'FooBarBaz'}
          expect(puppet_apply_stdout).to match %r{Updating}
          expect(puppet_apply_stdout).not_to match %r{Error:}
        end
      end
    end

    context 'when handling versions' do
      let(:manifest) { "test_custom_insync { example: ensure => 'present', #{test_key_value_pairs} }" }

      context 'when handling exact version strings' do
        context 'when the should and actual versions are identical' do
          let(:test_key_value_pairs) { "version => '1.2.3'" }

          it 'makes no changes and does not error' do
            expect(puppet_apply_stdout).not_to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end

        context 'when the should and actual versions differ' do
          let(:test_key_value_pairs) { "version => '3.2.1'" }

          it 'changes the version without erroring' do
            expect(puppet_apply_stdout).to match %r{version changed '1.2.3' to '3.2.1'}
            expect(puppet_apply_stdout).to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end
      end

      context 'when handling custom version strings' do
        context 'when the custom version string comparison is satisfied by the actual value' do
          let(:test_key_value_pairs) { "version => '> 1.0.0'" }

          it 'makes no changes and does not error' do
            expect(puppet_apply_stdout).not_to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end

        context 'when the custom version string comparison is not satisfied by the actual value' do
          let(:test_key_value_pairs) { "version => '> 2.0.0'" }

          it 'changes to a satisfactory version without erroring' do
            expect(puppet_apply_stdout).to match %r{The actual version \(1.2.3\) does not meet the custom version bound \(> 2.0.0\); updating to a version that does}
            expect(puppet_apply_stdout).to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end
      end

      context 'when handling minimum version bounds' do
        context 'when the minimum version bound is satisfied by the actual value' do
          let(:test_key_value_pairs) { "minimum_version => '1.0.0'" }

          it 'makes no changes and does not error' do
            expect(puppet_apply_stdout).not_to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end

        context 'when the minimum version bound is not satisfied by the actual value' do
          let(:test_key_value_pairs) { "minimum_version => '2.0.0'" }

          it 'changes to a satisfactory version without erroring' do
            expect(puppet_apply_stdout).to match %r{The actual version \(1.2.3\) does not meet the minimum version bound \(2.0.0\); updating to a version that does}
            expect(puppet_apply_stdout).to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end
      end

      context 'when handling maximum version bounds' do
        context 'when the maximum version bound is satisfied by the actual value' do
          let(:test_key_value_pairs) { "maximum_version => '2.0.0'" }

          it 'makes no changes and does not error' do
            expect(puppet_apply_stdout).not_to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end

        context 'when the maximum version bound is not satisfied by the actual value' do
          let(:test_key_value_pairs) { "maximum_version => '1.0.0'" }

          it 'changes to a satisfactory version without erroring' do
            expect(puppet_apply_stdout).to match %r{The actual version \(1.2.3\) does not meet the maximum version bound \(1.0.0\); updating to a version that does}
            expect(puppet_apply_stdout).to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end
      end

      context 'when handling combined minimum and maximum version bounds' do
        context 'when the combined version bounds are satisfied by the actual value' do
          let(:test_key_value_pairs) { "minimum_version => '1.0.0', maximum_version => '2.0.0'" }

          it 'makes no changes and does not error' do
            expect(puppet_apply_stdout).not_to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end

        context 'when the combined version bounds are not satisfied by the actual value' do
          let(:test_key_value_pairs) { "minimum_version => '1.0.0', maximum_version => '1.2.0'" }

          it 'changes to a satisfactory version without erroring' do
            expect(puppet_apply_stdout).to match %r{The actual version \(1.2.3\) does not meet the combined minimum \(1.0.0\) and maximum \(1.2.0\) bounds; updating to a version which does.}
            expect(puppet_apply_stdout).to match %r{Updating}
            expect(puppet_apply_stdout).not_to match %r{Error:}
          end
        end
      end
    end
  end
end
