require 'register_transformer_sk/bods_mapping/person_statement'
require 'register_transformer_sk/bods_mapping/child_entity_statement'
require 'register_transformer_sk/bods_mapping/ownership_or_control_statement'

module RegisterTransformerSk
  module BodsMapping
    class RecordProcessor
      def initialize(
        entity_resolver: nil,
        person_statement_mapper: BodsMapping::PersonStatement,
        child_entity_statement_mapper: BodsMapping::ChildEntityStatement,
        ownership_or_control_statement_mapper: BodsMapping::OwnershipOrControlStatement,
        bods_publisher: nil,
        error_adapter: nil
      )
        @entity_resolver = entity_resolver
        @bods_publisher = bods_publisher
        @person_statement_mapper = person_statement_mapper
        @child_entity_statement_mapper = child_entity_statement_mapper
        @ownership_or_control_statement_mapper = ownership_or_control_statement_mapper
        @error_adapter = error_adapter
      end

      def process(sk_record)
        # Pre-emptive check for pagination in child entities. We've never seen it,
        # but we think it's theoretically possible and we want to know asap if it
        # appears because it will mean we miss data
        # if sk_record[:'PartneriVerejnehoSektora@odata.nextLink']
        #  error_adapter && error_adapter.error(
        #    "SK record Id: #{record.Id} has paginated child entities (PartneriVerejnehoSektora)")
        # end

        child_entity = map_child_entity(sk_record)
        return unless child_entity

        child_entity = bods_publisher.publish(child_entity)

        parent_records = sk_record.KonecniUzivateliaVyhod
        parent_records.each do |parent_record|
          parent_entity = map_parent_entity(parent_record)
          parent_entity = bods_publisher.publish(parent_entity)

          relationship = map_relationship(sk_record, child_entity, parent_entity)
          bods_publisher.publish(relationship)
        end
      end

      private

      attr_reader :entity_resolver, :person_statement_mapper, :error_adapter,
                  :child_entity_statement_mapper, :ownership_or_control_statement_mapper, :bods_publisher

      def map_parent_entity(parent_record)
        person_statement_mapper.call(parent_record)
      end

      def map_child_entity(sk_record)
        child_entity_statement_mapper.call(sk_record, entity_resolver:)
      end

      def map_relationship(sk_record, child_entity, parent_entity)
        ownership_or_control_statement_mapper.call(
          sk_record,
          source_statement: parent_entity,
          target_statement: child_entity,
        )
      end
    end
  end
end
