# frozen_string_literal: true

require 'register_common/services/stream_client_kinesis'
require 'register_sources_bods/services/publisher'
require 'register_sources_oc/services/resolver_service'
require 'register_sources_sk/structs/record'

require_relative '../bods_mapping/record_processor'
require_relative '../config/adapters'
require_relative '../config/settings'

module RegisterTransformerSk
  module Apps
    class Transformer
      def initialize(bods_publisher: nil, entity_resolver: nil, s3_adapter: nil, bods_mapper: nil)
        bods_publisher ||= RegisterSourcesBods::Services::Publisher.new
        entity_resolver ||= RegisterSourcesOc::Services::ResolverService.new
        s3_adapter ||= RegisterTransformerSk::Config::Adapters::S3_ADAPTER
        @bods_mapper = bods_mapper || RegisterTransformerSk::BodsMapping::RecordProcessor.new(
          entity_resolver:,
          bods_publisher:
        )
        @stream_client = RegisterCommon::Services::StreamClientKinesis.new(
          credentials: RegisterTransformerSk::Config::AWS_CREDENTIALS,
          stream_name: ENV.fetch('SK_STREAM', 'SK_STREAM'),
          s3_adapter:,
          s3_bucket: ENV.fetch('BODS_S3_BUCKET_NAME', nil)
        )
        @consumer_id = 'RegisterTransformerSk'
      end

      def call
        stream_client.consume(consumer_id) do |record_data|
          record = JSON.parse(record_data, symbolize_names: true)

          begin
            sk_record = RegisterSourcesSk::Record[**record]
            bods_mapper.process(sk_record)
          rescue StandardError => e
            print 'Got error: ', e, ' for record: ', record_data, "\n\n"
          end
        end
      end

      private

      attr_reader :bods_mapper, :stream_client, :consumer_id
    end
  end
end
