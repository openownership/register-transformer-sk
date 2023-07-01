require 'register_sources_bods/structs/person_statement'
require 'register_sources_bods/structs/source'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'countries'
require 'iso8601'

module RegisterTransformerSk
  module BodsMapping
    class PersonStatement
      ID_PREFIX = 'openownership-register-'.freeze

      def self.call(sk_record)
        new(sk_record).call
      end

      def initialize(sk_record)
        @sk_record = sk_record
      end

      def call
        RegisterSourcesBods::PersonStatement[{
          statementType: statement_type,
          isComponent: false,
          personType: person_type,
          names:,
          identifiers:,
          nationalities:,
          birthDate: birth_date,
          addresses:,
          source:,
        }.compact]
      end

      private

      attr_reader :sk_record

      def statement_type
        RegisterSourcesBods::StatementTypes['personStatement']
      end

      def person_type
        RegisterSourcesBods::PersonTypes['knownPerson'] # TODO: KNOWN_PERSON, ANONYMOUS_PERSON, UNKNOWN_PERSON
      end

      def identifiers
        [
          RegisterSourcesBods::Identifier.new(
            id: sk_record.Id.to_s,
            schemeName: 'SK Register Partnerov Verejného Sektora',
          ),
        ]
      end

      def names
        [
          RegisterSourcesBods::Name.new(
            type: RegisterSourcesBods::NameTypes['individual'],
            fullName: name_string,
          ),
        ]
      end

      def nationalities
        nationality = country_from_nationality.try(:alpha2)

        return unless nationality

        country = ISO3166::Country[nationality]
        return nil if country.blank?

        [
          RegisterSourcesBods::Country.new(name: country.name, code: country.alpha2),
        ]
      end

      def country_from_nationality
        ISO3166::Country.find_country_by_number(sk_record.StatnaPrislusnost.StatistickyKod)
      end

      def birth_date
        entity_dob(sk_record.DatumNarodenia).to_s
      end

      def addresses
        address = sk_record.Adresa.presence && address_string(sk_record.Adresa)

        return [] if address.blank?

        nationality = country_from_nationality
        return unless nationality

        country = nationality.try(:alpha2)

        return [] if country.blank? # TODO: check this

        [
          RegisterSourcesBods::Address.new(
            type: RegisterSourcesBods::AddressTypes['registered'], # TODO: check this
            address:,
            # postCode: nil,
            country:,
          ),
        ]
      end

      def source
        RegisterSourcesBods::Source.new(
          type: RegisterSourcesBods::SourceTypes['officialRegister'],
          description: 'SK Register Partnerov Verejného Sektora',
          url: "https://rpvs.gov.sk/OpenData/Partneri",
          retrievedAt: Time.now.utc.to_date.to_s, # TODO: fix publication date, # TODO: add retrievedAt to sk_record iso8601
          assertedBy: nil, # TODO: if it is a combination of sources (DK and OpenCorporates), is it us?
        )
      end

      def address_string(address)
        first_line = [address.OrientacneCislo, address.MenoUlice].map(&:presence).compact.join(' ')

        [first_line, address.Mesto, address.Psc].map(&:presence).compact.map(&:strip).join(', ')
      end

      def name_string
        [sk_record.Meno, sk_record.Priezvisko].map(&:presence).compact.join(' ')
      end

      def entity_dob(timestamp)
        return unless timestamp

        ISO8601::Date.new(timestamp.split('T')[0])
      end
    end
  end
end
