require 'register_transformer_sk/config/settings'
require 'register_transformer_sk/config/adapters'
require 'register_sources_bods/services/publisher'
require 'register_transformer_sk/bods_mapping/record_processor'
require 'register_sources_sk/structs/record'
require 'register_sources_oc/services/resolver_service'
require 'register_common/services/stream_client_kinesis'

$stdout.sync = true

module RegisterTransformerSk
  module Apps
    class Transformer
      def initialize(bods_publisher: nil, entity_resolver: nil, s3_adapter: nil, bods_mapper: nil)
        bods_publisher ||= RegisterSourcesBods::Services::Publisher.new
        entity_resolver ||= RegisterSourcesOc::Services::ResolverService.new
        s3_adapter ||= RegisterTransformerSk::Config::Adapters::S3_ADAPTER
        @bods_mapper = bods_mapper || RegisterTransformerSk::BodsMapping::RecordProcessor.new(
          entity_resolver: entity_resolver,
          bods_publisher: bods_publisher,
        )
        @stream_client = RegisterCommon::Services::StreamClientKinesis.new(
          credentials: RegisterTransformerSk::Config::AWS_CREDENTIALS,
          stream_name: ENV.fetch('SK_STREAM', 'SK_STREAM'),
          s3_adapter: s3_adapter,
          s3_bucket: ENV['BODS_S3_BUCKET_NAME'],
        )
        @consumer_id = "RegisterTransformerSk"
      end

      def call
        stream_client.consume(consumer_id) do |record_data|
          record = JSON.parse(record_data, symbolize_names: true)

          begin
            sk_record = RegisterSourcesSk::Record[**record]
            bods_mapper.process(sk_record)
          rescue => e
            print "Got error: ", e, " for record: ", record_data, "\n\n"
          end
        end
      end

      private

      attr_reader :bods_mapper, :stream_client, :consumer_id
      
      def handle_records(records)
        records.each do |record|
          bods_mapper.process sk_record
        end
      end
    end
  end
end
