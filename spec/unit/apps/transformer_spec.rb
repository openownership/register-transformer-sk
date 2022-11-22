require 'json'
require 'register_transformer_sk/apps/transformer'

RSpec.describe RegisterTransformerSk::Apps::Transformer do
  subject do
    described_class.new(
      bods_publisher: bods_publisher,
      entity_resolver: entity_resolver,
      bods_mapper: bods_mapper
    )
  end

  let(:bods_publisher) { double 'bods_publisher' }
  let(:entity_resolver) { double 'entity_resolver' }
  let(:bods_mapper) { double 'bods_mapper' }

  describe '#call' do
    it 'consumes and processes each record' do
      record_data = {
        "Id": 1,
        "PartneriVerejnehoSektora": [
          {
            "Id": 1,
            "Meno": nil,
            "Priezvisko": nil,
            "DatumNarodenia": nil,
            "ObchodneMeno": "Example Slovak Company",
            "Ico": "1234567",
            "PlatnostOd": "2015-01-01T00:00:00+01:00",
            "PlatnostDo": nil,
            "Adresa": {
              "MenoUlice": "Example Street",
              "OrientacneCislo": "1234/1",
              "Mesto": "Example Place",
              "Psc": "12345"
            }
          }
        ],
        "KonecniUzivateliaVyhod": [
          {
            "Id": 1,
            "Meno": "Example",
            "Priezvisko": "Person 1",
            "DatumNarodenia": "1950-01-01T00:00:00+02:00",
            "PlatnostOd": "2015-01-01T00:00:00+01:00",
            "PlatnostDo": nil,
            "StatnaPrislusnost": {
              "StatistickyKod": "703"
            },
            "Adresa": {
              "MenoUlice": "Example Street",
              "OrientacneCislo": "1234/1",
              "Mesto": "Example Place",
              "Psc": "12345"
            }
          },
          {
            "Id": 2,
            "Meno": "Example",
            "Priezvisko": "Person 2",
            "DatumNarodenia": "1950-01-01T00:00:00+02:00",
            "PlatnostOd": "2015-01-01T00:00:00+01:00",
            "PlatnostDo": nil,
            "StatnaPrislusnost": {
              "StatistickyKod": "703"
            },
            "Adresa": {
              "MenoUlice": "Example Street",
              "OrientacneCislo": "1234/2",
              "Mesto": "Example Place",
              "Psc": "12345"
            }
          },
          {
            "Id": 3,
            "Meno": "Example",
            "Priezvisko": "Person 3",
            "DatumNarodenia": "1950-01-01T00:00:00+02:00",
            "PlatnostOd": "2015-01-01T00:00:00+01:00",
            "PlatnostDo": nil,
            "StatnaPrislusnost": {
              "StatistickyKod": "703"
            },
            "Adresa": {
              "MenoUlice": "Example Street",
              "OrientacneCislo": "1234/3",
              "Mesto": "Example Place",
              "Psc": "12345"
            }
          }
        ]
      }
      expect(stream_client).to receive(:consume).with('RegisterTransformerSk').and_yield(
        record_data.to_json
      )

      expect(bods_mapper).to receive(:process)
    end
  end
end
