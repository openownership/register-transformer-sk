require 'active_support/testing/time_helpers'

require 'register_transformer_sk/bods_mapping/child_entity_statement'
require 'register_sources_sk/structs/record'
require 'register_sources_oc/structs/resolver_response'

RSpec.describe RegisterTransformerSk::BodsMapping::ChildEntityStatement do
  include ActiveSupport::Testing::TimeHelpers

  subject { described_class.new(sk_record, entity_resolver:, geocoder_client:) }

  let(:entity_resolver) { double 'entity_resolver' }
  let(:geocoder_client) { double 'geocoder_client' }

  let(:sk_record) do
    data = {
      Id: 1,
      PartneriVerejnehoSektora: [
        {
          Id: 1,
          Meno: nil,
          Priezvisko: nil,
          DatumNarodenia: nil,
          ObchodneMeno: "Example Slovak Company",
          Ico: "1234567",
          PlatnostOd: "2015-01-01T00:00:00+01:00",
          PlatnostDo: nil,
          Adresa: {
            MenoUlice: "Example Street",
            OrientacneCislo: "1234/1",
            Mesto: "Example Place",
            Psc: "12345",
          },
        },
      ],
      KonecniUzivateliaVyhod: [
        {
          Id: 1,
          Meno: "Example",
          Priezvisko: "Person 1",
          DatumNarodenia: "1950-01-01T00:00:00+02:00",
          PlatnostOd: "2015-01-01T00:00:00+01:00",
          PlatnostDo: nil,
          StatnaPrislusnost: {
            StatistickyKod: "703",
          },
          Adresa: {
            MenoUlice: "Example Street",
            OrientacneCislo: "1234/1",
            Mesto: "Example Place",
            Psc: "12345",
          },
        },
        {
          Id: 2,
          Meno: "Example",
          Priezvisko: "Person 2",
          DatumNarodenia: "1950-01-01T00:00:00+02:00",
          PlatnostOd: "2015-01-01T00:00:00+01:00",
          PlatnostDo: nil,
          StatnaPrislusnost: {
            StatistickyKod: "703",
          },
          Adresa: {
            MenoUlice: "Example Street",
            OrientacneCislo: "1234/2",
            Mesto: "Example Place",
            Psc: "12345",
          },
        },
        {
          Id: 3,
          Meno: "Example",
          Priezvisko: "Person 3",
          DatumNarodenia: "1950-01-01T00:00:00+02:00",
          PlatnostOd: "2015-01-01T00:00:00+01:00",
          PlatnostDo: nil,
          StatnaPrislusnost: {
            StatistickyKod: "703",
          },
          Adresa: {
            MenoUlice: "Example Street",
            OrientacneCislo: "1234/3",
            Mesto: "Example Place",
            Psc: "12345",
          },
        },
      ],
    }
    RegisterSourcesSk::Record[data]
  end

  before { travel_to Time.at(1_663_187_854) }
  after { travel_back }

  it 'maps successfully' do # rubocop:disable RSpec/ExampleLength
    expect(geocoder_client).to receive(:jurisdiction).with(
      "1234/1 Example Street, Example Place, 12345",
    ).and_return 'sk'

    expect(entity_resolver).to receive(:resolve).with(
      RegisterSourcesOc::ResolverRequest[{
        company_number: '1234567',
        jurisdiction_code: "sk",
        name: "Example Slovak Company",
      }.compact],
    ).and_return RegisterSourcesOc::ResolverResponse[{
      resolved: true,
      reconciliation_response: nil,
      company_number: '1234567',
      # name: "Example Slovak Company",
      company: {
        company_number: '1234567',
        jurisdiction_code: 'gb',
        name: "Foo Bar Limited",
        company_type: 'company_type',
        incorporation_date: '2020-01-09',
        dissolution_date: '2021-09-07',
        restricted_for_marketing: nil,
        registered_address_in_full: 'registered address',
        registered_address_country: "United Kingdom",
      },
      add_ids: [
        {
          company_number: '1234567',
          jurisdiction_code: 'sk',
          uid: 'XXXXXXXXXXXXX1234567',
          identifier_system_code: 'lei',
        },
      ],
    }]

    result = subject.call

    expect(result).to be_a RegisterSourcesBods::EntityStatement
    expect(result.to_h).to eq(
      {
        addresses: [
          {
            address: "1234/1 Example Street, Example Place, 12345",
            country: "SK",
            type: "registered",
          },
        ],
        dissolutionDate: "2021-09-07",
        entityType: "registeredEntity",
        foundingDate: "2020-01-09",
        name: "Example Slovak Company",
        identifiers: [
          {
            id: "1234567",
            scheme: "SK-ORSR",
            schemeName: "Ministry of Justice Business Register",
          },
          {
            id: "https://opencorporates.com/companies//1234567",
            schemeName: "OpenCorporates",
            uri: "https://opencorporates.com/companies//1234567",
          },
          {
            id: "XXXXXXXXXXXXX1234567",
            scheme: "XI-LEI",
            schemeName: "Global Legal Entity Identifier Index",
            uri: "https://search.gleif.org/#/record/XXXXXXXXXXXXX1234567",
          },
        ],
        isComponent: false,
        statementType: "entityStatement",
      },
    )
  end
end
