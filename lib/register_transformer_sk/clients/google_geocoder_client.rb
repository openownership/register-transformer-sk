require 'geokit'

module RegisterTransformerSk
  module Clients
    class GoogleGeocoderClient
      def initialize(api_key: nil, error_adapter: nil)
        Geokit::Geocoders::GoogleGeocoder.api_key = api_key || ENV['GOOGLE_GEOCODE_API_KEY']
        @error_adapter = error_adapter
      end

      def jurisdiction(address_string)
        result = Geokit::Geocoders::GoogleGeocoder.geocode(address_string)
        return nil unless result.success?

        result.country_code.downcase
      rescue StandardError => e
        error_adapter.error(e)
        nil
      end

      private

      attr_reader :error_adapter
    end
  end
end
