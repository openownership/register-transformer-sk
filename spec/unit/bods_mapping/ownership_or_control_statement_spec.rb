# frozen_string_literal: true

require 'active_support/testing/time_helpers'

require 'register_transformer_sk/bods_mapping/ownership_or_control_statement'
require 'register_sources_sk/structs/record'

RSpec.describe RegisterTransformerSk::BodsMapping::OwnershipOrControlStatement do
  include ActiveSupport::Testing::TimeHelpers

  subject do
    described_class.new(
      sk_record,
      source_statement:,
      target_statement:
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
        },
        {
          Id: 2,
          Meno: 'Example',
          Priezvisko: 'Person 2',
          DatumNarodenia: '1950-01-01T00:00:00+02:00',
          PlatnostOd: '2015-01-01T00:00:00+01:00',
          PlatnostDo: nil,
          StatnaPrislusnost: {
            StatistickyKod: '703'
          },
          Adresa: {
            MenoUlice: 'Example Street',
            OrientacneCislo: '1234/2',
            Mesto: 'Example Place',
            Psc: '12345'
          }
        },
        {
          Id: 3,
          Meno: 'Example',
          Priezvisko: 'Person 3',
          DatumNarodenia: '1950-01-01T00:00:00+02:00',
          PlatnostOd: '2015-01-01T00:00:00+01:00',
          PlatnostDo: nil,
          StatnaPrislusnost: {
            StatistickyKod: '703'
          },
          Adresa: {
            MenoUlice: 'Example Street',
            OrientacneCislo: '1234/3',
            Mesto: 'Example Place',
            Psc: '12345'
          }
        }
      ]
    }
    RegisterSourcesSk::Record[data]
  end
  let(:source_statement) do
    double 'source_statement', statementID: 'sourceID', statementType: 'entityStatement', entityType: 'legalEntity'
  end
  let(:target_statement) do
    double 'target_statement', statementID: 'targetID'
  end

  before { travel_to Time.at(1_663_187_854) }
  after { travel_back }

  it 'maps successfully' do
    result = subject.call

    expect(result).to be_a RegisterSourcesBods::OwnershipOrControlStatement
    expect(result.to_h).to eq(
      {
        interestedParty: {
          describedByEntityStatement: 'sourceID'
        },
        interests: [],
        isComponent: false,
        statementDate: '2015-01-01',
        statementType: 'ownershipOrControlStatement',
        subject: {
          describedByEntityStatement: 'targetID'
        },
        source: {
          assertedBy: nil,
          description: 'SK Register Partnerov Verejného Sektora',
          retrievedAt: '2022-09-14',
          type: 'officialRegister',
          url: 'https://rpvs.gov.sk/OpenData/Partneri'
        }
      }
    )
  end
end
