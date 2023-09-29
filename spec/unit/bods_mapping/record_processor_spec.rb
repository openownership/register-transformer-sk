# frozen_string_literal: true

require 'active_support/testing/time_helpers'

require 'register_transformer_sk/bods_mapping/record_processor'
require 'register_sources_sk/structs/record'

RSpec.describe RegisterTransformerSk::BodsMapping::RecordProcessor do
  include ActiveSupport::Testing::TimeHelpers

  subject do
    described_class.new(
      entity_resolver:,
      person_statement_mapper:,
      child_entity_statement_mapper:,
      ownership_or_control_statement_mapper:,
      bods_publisher:
    )
  end

  let(:entity_resolver) { double 'entity_resolver' }
  let(:sk_record) do
    data = {
      Id: 1,
      PartneriVerejnehoSektora: [
        {
          Id: 1,
          Meno: nil,
          Priezvisko: nil,
          DatumNarodenia: nil,
          ObchodneMeno: 'Example Slovak Company',
          Ico: '1234567',
          PlatnostOd: '2015-01-01T00:00:00+01:00',
          PlatnostDo: nil,
          Adresa: {
            MenoUlice: 'Example Street',
            OrientacneCislo: '1234/1',
            Mesto: 'Example Place',
            Psc: '12345'
          }
        }
      ],
      KonecniUzivateliaVyhod: [
        {
          Id: 1,
          Meno: 'Example',
          Priezvisko: 'Person 1',
          DatumNarodenia: '1950-01-01T00:00:00+02:00',
          PlatnostOd: '2015-01-01T00:00:00+01:00',
          PlatnostDo: nil,
          StatnaPrislusnost: {
            StatistickyKod: '703'
          },
          Adresa: {
            MenoUlice: 'Example Street',
            OrientacneCislo: '1234/1',
            Mesto: 'Example Place',
            Psc: '12345'
          }
        }
      ]
    }
    RegisterSourcesSk::Record[data]
  end
  let(:person_statement_mapper) { double 'person_statement_mapper' }
  let(:child_entity_statement_mapper) { double 'child_entity_statement_mapper' }
  let(:ownership_or_control_statement_mapper) { double 'ownership_or_control_statement_mapper' }
  let(:bods_publisher) { double 'bods_publisher' }

  before { travel_to Time.at(1_663_187_854) }
  after { travel_back }

  it 'processes record' do
    child_entity = double 'child_entity'
    expect(child_entity_statement_mapper).to receive(:call).with(
      sk_record,
      entity_resolver:
    ).and_return child_entity

    parent_entity = double 'parent_entity'
    expect(person_statement_mapper).to receive(:call).with(
      sk_record.KonecniUzivateliaVyhod.first
    ).and_return parent_entity

    source_statement = double 'source_statement'
    target_statement = double 'target_statement'

    ownership_or_control_statement = double 'ownership_or_control_statement'
    expect(ownership_or_control_statement_mapper).to receive(:call).with(
      sk_record,
      source_statement:,
      target_statement:
    ).and_return ownership_or_control_statement

    expect(bods_publisher).to receive(:publish).with(parent_entity).and_return source_statement
    expect(bods_publisher).to receive(:publish).with(child_entity).and_return target_statement
    expect(bods_publisher).to receive(:publish).with(ownership_or_control_statement)

    subject.process sk_record
  end
end
