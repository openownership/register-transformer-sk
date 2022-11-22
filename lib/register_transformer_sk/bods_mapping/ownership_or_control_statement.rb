require 'register_sources_bods/constants/publisher'
require 'register_sources_bods/structs/interest'
require 'register_sources_bods/structs/entity_statement'
require 'register_sources_bods/structs/ownership_or_control_statement'
require 'register_sources_bods/structs/publication_details'
require 'register_sources_bods/structs/share'
require 'register_sources_bods/structs/source'
require 'register_sources_bods/structs/subject'

require 'active_support/core_ext/time'
Time.zone='UTC'

module RegisterTransformerSk
  module BodsMapping
    class OwnershipOrControlStatement
      UnsupportedSourceStatementTypeError = Class.new(StandardError)

      ID_PREFIX = 'openownership-register-'.freeze

      def self.call(sk_record, **kwargs)
        new(sk_record, **kwargs).call
      end

      def initialize(sk_record, source_statement: nil, target_statement: nil)
        @sk_record = sk_record
        @source_statement = source_statement
        @target_statement = target_statement
      end

      def call
        RegisterSourcesBods::OwnershipOrControlStatement[{
          statementID: statement_id,
          statementType: statement_type,
          statementDate: statement_date,
          isComponent: false,
          subject: subject,
          interestedParty: interested_party,
          interests: interests,
          publicationDetails: publication_details,
          source: source
        }.compact]
      end

      private

      attr_reader :sk_record, :source_statement, :target_statement

      def data
        sk_record.data
      end

      def item
        return @item if @item

        right_now = Time.zone.now.iso8601
        @item = sk_record.PartneriVerejnehoSektora.max_by do |p|
          p.PlatnostDo.nil? ? right_now : p.PlatnostDo
        end
      end

      def statement_id
        "TODO" # filled in when published
      end

      def statement_type
        RegisterSourcesBods::StatementTypes['ownershipOrControlStatement']
      end

      def statement_date
        Date.parse(item.PlatnostOd).to_s
      end

      def subject
        RegisterSourcesBods::Subject.new(
          describedByEntityStatement: target_statement.statementID
        )
      end

      def interests
        # started_date: Date.parse(item['PlatnostOd']).to_s,
        # ended_date: item['PlatnostDo'].presence && Date.parse(item['PlatnostDo']).to_s,
        # TODO: these seem to be unimplemented for SK in Register
        []
      end

      def interested_party
        case source_statement.statementType
        when RegisterSourcesBods::StatementTypes['personStatement']
          RegisterSourcesBods::InterestedParty[{
            describedByPersonStatement: source_statement.statementID
          }]
        when RegisterSourcesBods::StatementTypes['entityStatement']
          case source_statement.entityType
          when RegisterSourcesBods::EntityTypes['unknownEntity']
            RegisterSourcesBods::InterestedParty[{
              unspecified: source_statement.unspecifiedEntityDetails
            }.compact]
          when RegisterSourcesBods::EntityTypes['legalEntity']
            RegisterSourcesBods::InterestedParty[{
              describedByEntityStatement: source_statement.statementID
            }]
          else
            RegisterSourcesBods::InterestedParty[{}] # TODO: raise error
          end
        else
          raise UnsupportedSourceStatementTypeError
        end
      end

      def publication_details
        RegisterSourcesBods::PublicationDetails.new(
          publicationDate: Time.now.utc.to_date.to_s,
          bodsVersion: RegisterSourcesBods::BODS_VERSION,
          license: RegisterSourcesBods::BODS_LICENSE,
          publisher: RegisterSourcesBods::PUBLISHER
        )
      end

      def source
        RegisterSourcesBods::Source.new(
          type: RegisterSourcesBods::SourceTypes['officialRegister'],
          description: 'SK Register Partnerov Verejného Sektora',
          url: "https://rpvs.gov.sk/OpenData/Partneri",
          retrievedAt: Time.now.utc.to_date.to_s, # TODO: fix publication date, # TODO: add retrievedAt to record iso8601
          assertedBy: nil # TODO: if it is a combination of sources (DK and OpenCorporates), is it us?
        )
      end
    end
  end
end
