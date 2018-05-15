# test_module::autorequire_cycle
#
# This class is used to test autorequires.
# With make_cycle set to false, this should compile without errors or cycles. When make_cycle is set to true, autorequires will be used to
# construct a dependency cycle. This makes it possible to test exactly the function of the autorequires implementation.
#
# @summary This class is used to test autorequires.
#
# @example
#   include test_module::autorequire_cycle
class test_module::autorequire_cycle (
  Boolean $make_cycle
) {
  test_autorequire { 'a':
    target => 'b',
  }
  test_autorequire { 'b':
    target => 'c',
  }
  test_autorequire { 'c':
    target => $make_cycle ? { true => 'a', false => undef },
  }
}
