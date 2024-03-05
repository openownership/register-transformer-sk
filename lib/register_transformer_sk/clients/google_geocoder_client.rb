# frozen_string_literal: true

require 'geokit'

module RegisterTransformerSk
  module Clients
    class GoogleGeocoderClient
      def initialize(api_key: nil, error_adapter: nil)
        Geokit::Geocoders::GoogleGeocoder.api_key = api_key || ENV.fetch('GOOGLE_GEOCODE_API_KEY', nil)
        @error_adapter = error_adapter
      end

      def jurisdiction(address_string)
        result = Geokit::Geocoders::GoogleGeocoder.geocode(address_string)
        return nil unless result.success?

        result.country_code.downcase
      end

      private

      attr_reader :error_adapter
    end
  end
end
