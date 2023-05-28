require 'logger'

require 'register_sources_bods/enums/entity_types'
require 'register_sources_bods/enums/statement_types'
require 'register_sources_bods/structs/address'
require 'register_sources_bods/structs/entity_statement'
require 'register_sources_bods/structs/identifier'
require 'register_sources_bods/structs/jurisdiction'
require 'register_sources_bods/constants/publisher'
require 'register_sources_bods/mappers/resolver_mappings'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/time'
require 'active_support/core_ext/date'
require 'active_support/core_ext/string/conversions'
require 'countries'
require 'iso8601'

Time.zone = 'UTC'

require 'register_sources_oc/structs/resolver_request'

require 'register_transformer_sk/clients/google_geocoder_client'

module RegisterTransformerSk
  module BodsMapping
    class ChildEntityStatement
      include RegisterSourcesBods::Mappers::ResolverMappings

      ID_PREFIX = 'openownership-register-'.freeze
      OPEN_CORPORATES_SCHEME_NAME = 'OpenCorporates'.freeze

      def self.call(record, entity_resolver: nil, geocoder_client: nil, logger: nil)
        new(record, entity_resolver:, geocoder_client:, logger: nil).call
      end

      def initialize(record, entity_resolver: nil, geocoder_client: nil, logger: nil)
        @record = record
        @entity_resolver = entity_resolver
        @geocoder_client = geocoder_client || Clients::GoogleGeocoderClient.new
        @logger = logger || Logger.new($stdout)
      end

      def call
        if item.nil?
          logger.warn("[#{self.class.name}] record Id: #{record.Id} has no current child entity (PartneriVerejnehoSektora)")
          return
        elsif item.ObchodneMeno.nil?
          logger.warn("[#{self.class.name}] record Id: #{record.Id} has a child entity (PartneriVerejnehoSektora) with no company name (ObchodneMeno)")
          return
        end

        RegisterSourcesBods::EntityStatement[{
          statementID: statement_id,
          statementType: RegisterSourcesBods::StatementTypes['entityStatement'],
          isComponent: false,
          name: company_name,
          entityType: RegisterSourcesBods::EntityTypes['registeredEntity'],
          incorporatedInJurisdiction: incorporated_in_jurisdiction,
          identifiers: [
            RegisterSourcesBods::Identifier.new(
              scheme: 'SK-ORSR',
              schemeName: 'Ministry of Justice Business Register',
              id: item.Ico,
            ),
            open_corporates_identifier,
          ].compact,
          addresses:,
          foundingDate: founding_date,
          dissolutionDate: dissolution_date,
          publicationDetails: publication_details,
        }.compact]
      rescue RegisterSourcesOc::Clients::ReconciliationClient::Error => e
        logger.error e
        nil
      end

      private

      attr_reader :entity_resolver, :record, :geocoder_client, :logger

      def item
        return @item if @item

        right_now = Time.zone.now.iso8601
        @item = record.PartneriVerejnehoSektora.max_by do |p|
          p.PlatnostDo.nil? ? right_now : p.PlatnostDo
        end
      end

      def jurisdiction_code
        @jurisdiction_code ||= geocoder_client.jurisdiction(address)
      end

      def addresses
        return super if address.blank?

        nationality = ISO3166::Country[jurisdiction_code]
        return super unless nationality

        country = nationality.try(:alpha2)
        return super if country.blank? # TODO: check this

        [
          RegisterSourcesBods::Address.new(
            type: RegisterSourcesBods::AddressTypes['registered'], # TODO: check this
            address:,
            # postCode: nil,
            country:,
          ),
        ]
      end

      def address
        return @address if @address

        raw_address = item.Adresa
        first_line = [raw_address.OrientacneCislo, raw_address.MenoUlice].map(&:presence).compact.join(' ')

        @address = [first_line, raw_address.Mesto, raw_address.Psc].map(&:presence).compact.map(&:strip).join(', ')
      end

      def company_number
        jurisdiction_code == 'sk' ? item.Ico : nil
      end

      def company_name
        @company_name ||= item.ObchodneMeno.strip || name
      end

      def resolver_response
        return @resolver_response if @resolver_response

        @resolver_response = entity_resolver.resolve(
          RegisterSourcesOc::ResolverRequest[{
            company_number:,
            jurisdiction_code:,
            name: company_name,
          }.compact],
        )
      end

      def statement_id
        'TODO'
      end

      def publication_details
        RegisterSourcesBods::PublicationDetails.new(
          publicationDate: Time.now.utc.to_date.to_s, # TODO: fix publication date
          bodsVersion: RegisterSourcesBods::BODS_VERSION,
          license: RegisterSourcesBods::BODS_LICENSE,
          publisher: RegisterSourcesBods::PUBLISHER,
        )
      end
    end
  end
end
