# Test all metaparameters from https://puppet.com/docs/puppet/5.5/metaparameter.html with a resource API type,
# to ensure that there are no hidden breakages.
#
# @summary A short summary of the purpose of this class
#
# @example
#   include test_module::metaparam_support
class test_module::metaparam_support {
  notify { [a,b,c,d]: }

  schedule { 'everyday':
    period => daily,
    range  => '2-4'
  }

  test_bool { 'foo':
    test_bool       => true,
    test_bool_param => true,
    # provider => no parameter named 'provider'
    alias           => 'bar',
    audit           => all,
    before          => Notify['a'],
    # consume => not supported for resources
    # export => not supported for resources
    loglevel        => crit,
    noop            => false,
    notify          => Notify['b'],
    require         => Notify['c'],
    schedule        => 'everyday',
    # stage => Only classes can set 'stage'; normal resources like Test_bool[f] cannot change run stage
    subscribe       => Notify['d'],
    tag             => [a,b,c],
  }

  @test_bool { 'virtual':
    test_bool       => true,
    test_bool_param => true,
  }

  Test_bool<||>
}
