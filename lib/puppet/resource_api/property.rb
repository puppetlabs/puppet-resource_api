require 'puppet/util'
require 'puppet/property'

module Puppet; module ResourceApi; end; end # predeclare the main module # rubocop:disable Style/Documentation,Style/ClassAndModuleChildren

# Class containing property functionality for ResourceApi.
class Puppet::ResourceApi::Property < Puppet::Property
  # This initialize takes arguments and sets up new property.
  # @param type_name the name of the Puppet Type
  # @param data_type the data type of property instance
  # @param attribute_name the name of attribue of the property
  # @param resource_hash the resource hash instance which is passed to the
  # parent class.
  def initialize(type_name, data_type, attribute_name, resource_hash)
    @type_name = type_name
    @data_type = data_type
    @attribute_name = attribute_name
    # Define class method insync?(is) if the name is :ensure
    def_insync? if @attribute_name == :ensure && self.class != Puppet::ResourceApi::Property
    # Pass resource to parent Puppet class.
    super(resource_hash)
  end

  # This method returns value of the property.
  # @return [type] the property value
  def should
    if @attribute_name == :ensure && rs_value.is_a?(String)
      rs_value.to_sym
    elsif rs_value == false
      # work around https://tickets.puppetlabs.com/browse/PUP-2368
      :false # rubocop:disable Lint/BooleanSymbol
    elsif rs_value == true
      # work around https://tickets.puppetlabs.com/browse/PUP-2368
      :true # rubocop:disable Lint/BooleanSymbol
    else
      rs_value
    end
  end

  # This method sets and returns value of the property and sets @shouldorig.
  # @param value the value to be set and clean
  # @return [type] the property value
  def should=(value)
    @shouldorig = value

    if @attribute_name == :ensure
      value = value.to_s
    end

    # Puppet requires the @should value to always be stored as an array. We do not use this
    # for anything else
    # @see Puppet::Property.should=(value)
    @should = [
      Puppet::ResourceApi::DataTypeHandling.mungify(
        @data_type,
        value,
        "#{@type_name}.#{@attribute_name}",
        Puppet::ResourceApi.caller_is_resource_app?,
      ),
    ]
  end

  # used internally
  # @returns the final mungified value of this property
  def rs_value
    @should ? @should.first : @should
  end

  # method overloaded only for the :ensure property, add option to check if the
  # rs_value matches is. Only if the class is child of
  # Puppet::ResourceApi::Property.
  def def_insync?
    define_singleton_method(:insync?) { |is| rs_value.to_s == is.to_s }
  end

  # puppet symbolizes some values through puppet/parameter/value.rb
  # (see .convert()), but (especially) Enums are strings. specifying a
  # munge block here skips the value_collection fallback in
  # puppet/parameter.rb's default .unsafe_munge() implementation.
  munge { |v| v }

  # stop puppet from trying to call into the provider when
  # no pre-defined values have been specified
  # "This is not the provider you are looking for." -- Obi-Wan Kaniesobi.
  def call_provider(_value); end
end
