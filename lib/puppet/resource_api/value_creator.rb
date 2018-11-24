module Puppet; module ResourceApi; end; end # predeclare the main module # rubocop:disable Style/Documentation,Style/ClassAndModuleChildren

# This class is responsible for setting default and alias values for the
# resource class.
class Puppet::ResourceApi::ValueCreator
  def initialize(resource_class, data_type, param_or_property, options = {})
    @resource_class = resource_class
    @data_type = data_type
    @param_or_property = param_or_property
    @options = options
  end

  # This method is responsible for all setup of the value mapping for desired
  # resource class.
  def create_values
    @resource_class.isnamevar if @options[:behaviour] == :namevar

    # read-only values do not need type checking, but can have default values
    if @options[:behaviour] != :read_only && @options.key?(:default)
      if @options[:default] == false
        # work around https://tickets.puppetlabs.com/browse/PUP-2368
        @resource_class.defaultto :false # rubocop:disable Lint/BooleanSymbol
      elsif @options[:default] == true
        # work around https://tickets.puppetlabs.com/browse/PUP-2368
        @resource_class.defaultto :true # rubocop:disable Lint/BooleanSymbol
      else
        # marshal the default option to decouple that from the actual value.
        # we cache the dumped value in `marshalled`, but use a block to
        # unmarshal everytime the value is requested. Objects that can't be
        # marshalled
        # See https://stackoverflow.com/a/8206537/4918
        marshalled = Marshal.dump(@options[:default])
        @resource_class.defaultto { Marshal.load(marshalled) } # rubocop:disable Security/MarshalLoad
      end
    end

    case @data_type
    when Puppet::Pops::Types::PStringType
      # require any string value
      def_newvalues(@resource_class, %r{})
    when Puppet::Pops::Types::PBooleanType
      def_newvalues(@resource_class, 'true', 'false')
      @resource_class.aliasvalue true, 'true'
      @resource_class.aliasvalue false, 'false'
      @resource_class.aliasvalue :true, 'true' # rubocop:disable Lint/BooleanSymbol
      @resource_class.aliasvalue :false, 'false' # rubocop:disable Lint/BooleanSymbol
    when Puppet::Pops::Types::PIntegerType
      def_newvalues(@resource_class, %r{^-?\d+$})
    when Puppet::Pops::Types::PFloatType, Puppet::Pops::Types::PNumericType
      def_newvalues(@resource_class, Puppet::Pops::Patterns::NUMERIC)
    end

    def_call_provider() if @param_or_property == :newproperty

    case @options[:type]
    when 'Enum[present, absent]'
      def_newvalues(@resource_class, 'absent', 'present')
    end
  end

  # Add the value to `this` property or param, depending on whether
  # param_or_property is `:newparam`, or `:newproperty`.
  def def_newvalues(this, *values)
    if @param_or_property == :newparam
      this.newvalues(*values)
    else
      values.each do |v|
        this.newvalue(v) {}
      end
    end
  end

  # stop puppet from trying to call into the provider when
  # no pre-defined values have been specified
  # "This is not the provider you are looking for." -- Obi-Wan Kaniesobi.
  def def_call_provider
    @resource_class.send(:define_method, :call_provider) { |value| }
  end
end
