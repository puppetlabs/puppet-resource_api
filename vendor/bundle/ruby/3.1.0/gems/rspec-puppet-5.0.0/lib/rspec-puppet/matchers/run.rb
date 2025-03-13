# frozen_string_literal: true

module RSpec::Puppet
  module FunctionMatchers
    class Run
      def matches?(func_obj)
        @func_obj = func_obj

        @has_returned = false
        begin
          # `*nil` does not evaluate to "no params" on ruby 1.8 :-(
          @actual_return = @params.nil? ? @func_obj.execute(&@block) : @func_obj.execute(*@params, &@block)
          @has_returned = true
        rescue Exception => e
          @actual_error = e
        end

        if @has_expected_error
          if @has_returned
            false
          elsif @actual_error.is_a?(@expected_error)
            case @expected_error_message
            when nil
              true
            when Regexp
              !(@actual_error.message =~ @expected_error_message).nil?
            else
              @actual_error.message == @expected_error_message
            end
          else # error did not match
            false
          end
        elsif @has_expected_return
          return false unless @has_returned

          case @expected_return
          when Regexp
            !(@actual_return =~ @expected_return).nil?
          when RSpec::Mocks::ArgumentMatchers::KindOf, RSpec::Matchers::AliasedMatcher
            @expected_return === @actual_return
          else
            @actual_return == @expected_return
          end

        else
          @has_returned
        end
      end

      def with_params(*params)
        @params = params
        # stringify immediately to protect us from the params being changed by
        # the subject, e.g. with params.shift
        @func_args = @params.inspect[1..-2]
        self
      end

      def with_lambda(&block)
        @block = block
        self
      end

      def and_return(value)
        @has_expected_return = true
        @expected_return = value
        @desc = if value.is_a? Regexp
                  "match #{value.inspect}"
                else
                  "return #{value.inspect}"
                end
        self
      end

      def and_raise_error(error_or_message, message = nil)
        @has_expected_error = true
        case error_or_message
        when String, Regexp
          @expected_error = Exception
          @expected_error_message = error_or_message
        else
          @expected_error = error_or_message
          @expected_error_message = message
        end

        if @expected_error_message.is_a? Regexp
          @desc = "raise an #{@expected_error} with the message matching #{@expected_error_message.inspect}"
        else
          @desc = "raise an #{@expected_error}"
          @desc += "with the message #{@expected_error_message.inspect}" unless @expected_error_message.nil?
        end
        self
      end

      def failure_message
        failure_message_generic(:should, @func_obj)
      end

      def failure_message_when_negated
        failure_message_generic(:should_not, @func_obj)
      end

      def description
        if @desc
          "run #{func_name}(#{func_params}) and #{@desc}"
        else
          "run #{func_name}(#{func_params}) without error"
        end
      end

      def supports_block_expectations
        true
      end

      def supports_value_expectations
        true
      end

      private

      def func_name
        @func_obj.func_name
      end

      def func_params
        @func_args
      end

      def failure_message_actual(type)
        if type != :should
          ''
        elsif @actual_error
          if @has_expected_return
            " instead of raising #{@actual_error.class.inspect}(#{@actual_error})\n#{@actual_error.backtrace.join("\n")}"
          else
            " instead of #{@actual_error.class.inspect}(#{@actual_error})\n#{@actual_error.backtrace.join("\n")}"
          end
        elsif @has_expected_error # function has returned
          " instead of returning #{@actual_return.inspect}"
        else
          " instead of #{@actual_return.inspect}"
        end
      end

      def failure_message_generic(type, _func_obj)
        # message is mutable
        message = +"expected #{func_name}(#{func_params}) to "
        message << 'not ' if type == :should_not

        if @has_expected_return
          message << "have returned #{@expected_return.inspect}"
        elsif @has_expected_error
          message << "have raised #{@expected_error.inspect}"
          message << " matching #{@expected_error_message.inspect}" if @expected_error_message
        else
          message << 'have run successfully'
        end
        message << failure_message_actual(type)
      end
    end
  end
end
