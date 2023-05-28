require 'active_support/testing/time_helpers'

require 'register_transformer_sk/bods_mapping/person_statement'
require 'register_sources_sk/structs/konecni_uzivatelia_vyhod'

RSpec.describe RegisterTransformerSk::BodsMapping::PersonStatement do
  include ActiveSupport::Testing::TimeHelpers

  subject { described_class.new(sk_record) }

  before { travel_to Time.at(1_663_187_854) }
  after { travel_back }

  let(:sk_record) do
    data = {
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
    }
    RegisterSourcesSk::KonecniUzivateliaVyhod[data]
  end

  it 'maps successfully' do
    result = subject.call

    expect(result).to be_a RegisterSourcesBods::PersonStatement
    expect(result.to_h).to eq(
      {
        addresses: [
          {
            address: "1234/1 Example Street, Example Place, 12345",
            country: "SK",
            type: "registered",
          },
        ],
        birthDate: "1950-01-01",
        identifiers: [
          { id: "1", schemeName: "SK Register Partnerov Verejného Sektora" },
        ],
        isComponent: false,
        names: [
          { fullName: "Example Person 1", type: "individual" },
        ],
        nationalities: [
          { code: "SK", name: "Slovakia" },
        ],
        personType: "knownPerson",
        publicationDetails: {
          bodsVersion: "0.2",
          license: "https://register.openownership.org/terms-and-conditions",
          publicationDate: "2022-09-14",
          publisher: {
            name: "OpenOwnership Register",
            url: "https://register.openownership.org",
          },
        },
        source: {
          assertedBy: nil,
          description: "SK Register Partnerov Verejného Sektora",
          retrievedAt: "2022-09-14",
          type: "officialRegister",
          url: "https://rpvs.gov.sk/OpenData/Partneri",
        },
        statementID: "TODO",
        statementType: "personStatement",
      },
    )
  end
end
