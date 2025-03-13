# frozen_string_literal: true

module Facts
  module Openbsd
    module Dmi
      module Bios
        class Version
          FACT_NAME = 'dmi.bios.version'
          ALIASES = 'bios_version'

          def call_the_resolver
            fact_value = Facter::Resolvers::Openbsd::DmiBios.resolve(:bios_version)
            [Facter::ResolvedFact.new(FACT_NAME, fact_value), Facter::ResolvedFact.new(ALIASES, fact_value, :legacy)]
          end
        end
      end
    end
  end
end
