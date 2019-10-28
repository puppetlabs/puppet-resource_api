require 'puppet/resource_api'
require 'puppet/resource_api/simple_provider'

# Implementation for the test_bool type using the Resource API.
class Puppet::Provider::TestFailure::TestFailure
  def get(_context)
    []
  end

  def set(context, changes)
    changes.each do |name, change|
      is = change[:is]
      should = change[:should]

      context.notice(name, "Creating '#{name}' with #{should.inspect}")
      if should[:failure]
        context.creating(name) do
          raise "A failure for #{name}"
        end
      end
      context.notice(name, "Finished")
    end
  end
end
