# frozen_string_literal: true

# The Singleton module implements the Singleton pattern.
#
# == Usage
#
# To use Singleton, include the module in your class.
#
#    class Klass
#       include Singleton
#       # ...
#    end
#
# This ensures that only one instance of Klass can be created.
#
#      a,b = Klass.instance, Klass.instance
#
#      a == b
#      # => true
#
#      Klass.new
#      # => NoMethodError - new is private ...
#
# The instance is created at upon the first call of Klass.instance().
#
#      class OtherKlass
#        include Singleton
#        # ...
#      end
#
#      ObjectSpace.each_object(OtherKlass){}
#      # => 0
#
#      OtherKlass.instance
#      ObjectSpace.each_object(OtherKlass){}
#      # => 1
#
#
# This behavior is preserved under inheritance and cloning.
#
# == Implementation
#
# This above is achieved by:
#
# *  Making Klass.new and Klass.allocate private.
#
# *  Overriding Klass.inherited(sub_klass) and Klass.clone() to ensure that the
#    Singleton properties are kept when inherited and cloned.
#
# *  Providing the Klass.instance() method that returns the same object each
#    time it is called.
#
# *  Overriding Klass._load(str) to call Klass.instance().
#
# *  Overriding Klass#clone and Klass#dup to raise TypeErrors to prevent
#    cloning or duping.
#
# == Singleton and Marshal
#
# By default Singleton's #_dump(depth) returns the empty string. Marshalling by
# default will strip state information, e.g. instance variables from the instance.
# Classes using Singleton can provide custom _load(str) and _dump(depth) methods
# to retain some of the previous state of the instance.
#
#    require 'singleton'
#
#    class Example
#      include Singleton
#      attr_accessor :keep, :strip
#      def _dump(depth)
#        # this strips the @strip information from the instance
#        Marshal.dump(@keep, depth)
#      end
#
#      def self._load(str)
#        instance.keep = Marshal.load(str)
#        instance
#      end
#    end
#
#    a = Example.instance
#    a.keep = "keep this"
#    a.strip = "get rid of this"
#
#    stored_state = Marshal.dump(a)
#
#    a.keep = nil
#    a.strip = nil
#    b = Marshal.load(stored_state)
#    p a == b  #  => true
#    p a.keep  #  => "keep this"
#    p a.strip #  => nil
#
module Singleton
  VERSION = "0.3.0"

  module SingletonInstanceMethods
    # Raises a TypeError to prevent cloning.
    def clone
      raise TypeError, "can't clone instance of singleton #{self.class}"
    end

    # Raises a TypeError to prevent duping.
    def dup
      raise TypeError, "can't dup instance of singleton #{self.class}"
    end

    # By default, do not retain any state when marshalling.
    def _dump(depth = -1)
      ''
    end
  end
  include SingletonInstanceMethods

  module SingletonClassMethods # :nodoc:

    def clone # :nodoc:
      Singleton.__init__(super)
    end

    # By default calls instance(). Override to retain singleton state.
    def _load(str)
      instance
    end

    def instance # :nodoc:
      @singleton__instance__ || @singleton__mutex__.synchronize { @singleton__instance__ ||= new }
    end

    private

    def inherited(sub_klass)
      super
      Singleton.__init__(sub_klass)
    end

    def set_instance(val)
      @singleton__instance__ = val
    end

    def set_mutex(val)
      @singleton__mutex__ = val
    end
  end

  def self.module_with_class_methods
    SingletonClassMethods
  end

  module SingletonClassProperties

    def self.included(c)
      # extending an object with Singleton is a bad idea
      c.undef_method :extend_object
    end

    def self.extended(c)
      # extending an object with Singleton is a bad idea
      c.singleton_class.send(:undef_method, :extend_object)
    end

    def __init__(klass) # :nodoc:
      klass.instance_eval {
        set_instance(nil)
        set_mutex(Thread::Mutex.new)
      }
      klass
    end

    private

    def append_features(mod)
      #  help out people counting on transitive mixins
      unless mod.instance_of?(Class)
        raise TypeError, "Inclusion of the OO-Singleton module in module #{mod}"
      end
      super
    end

    def included(klass)
      super
      klass.private_class_method :new, :allocate
      klass.extend module_with_class_methods
      Singleton.__init__(klass)
    end
  end
  extend SingletonClassProperties

  ##
  # :singleton-method: _load
  #  By default calls instance(). Override to retain singleton state.

  ##
  # :singleton-method: instance
  #  Returns the singleton instance.
end

if defined?(Ractor)
  module RactorLocalSingleton
    include Singleton::SingletonInstanceMethods

    module RactorLocalSingletonClassMethods
      include Singleton::SingletonClassMethods
      def instance
        set_mutex(Thread::Mutex.new) if Ractor.current[mutex_key].nil?
        return Ractor.current[instance_key] if Ractor.current[instance_key]
        Ractor.current[mutex_key].synchronize {
          return Ractor.current[instance_key] if Ractor.current[instance_key]
          set_instance(new())
        }
        Ractor.current[instance_key]
      end

      private

      def instance_key
        :"__RactorLocalSingleton_instance_with_class_id_#{object_id}__"
      end

      def mutex_key
        :"__RactorLocalSingleton_mutex_with_class_id_#{object_id}__"
      end

      def set_instance(val)
        Ractor.current[instance_key] = val
      end

      def set_mutex(val)
        Ractor.current[mutex_key] = val
      end
    end

    def self.module_with_class_methods
      RactorLocalSingletonClassMethods
    end

    extend Singleton::SingletonClassProperties
  end
end
