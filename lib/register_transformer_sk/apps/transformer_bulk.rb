# frozen_string_literal: true

require 'json'
require 'redis'
require 'register_common/services/file_reader'
require 'register_sources_bods/services/publisher'
require 'register_sources_oc/services/resolver_service'
require 'register_sources_sk/structs/record'

require_relative '../bods_mapping/record_processor'
require_relative '../config/adapters'
require_relative '../config/settings'

$stdout.sync = true

module RegisterTransformerSk
  module Apps
    class TransformerBulk
      BATCH_SIZE     = 25
      NAMESPACE      = 'SK_TRANSFORMER_BULK'
      PARALLEL_FILES = ENV.fetch('SK_PARALLEL_FILES', 5).to_i

      def self.bash_call(args)
        s3_prefix = args.last

        TransformerBulk.new.call(s3_prefix)
      end

      def initialize(s3_adapter: nil, bods_mapper: nil, redis: nil, s3_bucket: nil, file_reader: nil)
        @s3_adapter = s3_adapter || RegisterTransformerSk::Config::Adapters::S3_ADAPTER
        @bods_mapper = bods_mapper || RegisterTransformerSk::BodsMapping::RecordProcessor.new(
          entity_resolver: RegisterSourcesOc::Services::ResolverService.new,
          bods_publisher: RegisterSourcesBods::Services::Publisher.new
        )
        @redis = redis || Redis.new(url: ENV.fetch('REDIS_URL'))
        @s3_bucket = s3_bucket || ENV.fetch('BODS_S3_BUCKET_NAME')
        @file_reader = file_reader || RegisterCommon::Services::FileReader.new(s3_adapter: @s3_adapter,
                                                                               batch_size: BATCH_SIZE)
      end

      def call(s3_prefix)
        s3_paths = s3_adapter.list_objects(s3_bucket:, s3_prefix:)

        s3_paths.each_slice(PARALLEL_FILES) do |s3_paths_batch|
          threads = []
          s3_paths_batch.each do |s3_path|
            threads << Thread.new { process_s3_path(s3_path) }
          end
          threads.each(&:join)
        end
      end

      private

      attr_reader :bods_mapper, :redis, :s3_bucket, :s3_adapter, :file_reader

      def process_s3_path(s3_path)
        if file_processed?(s3_path)
          print "Skipping #{s3_path}\n"
          return
        end

        print "#{Time.now} Processing #{s3_path}\n"
        file_reader.read_from_s3(s3_bucket:, s3_path:) do |rows|
          process_rows rows
        end

        mark_file_complete(s3_path)
        print "#{Time.now} Completed #{s3_path}\n"
      end

      def process_rows(rows)
        rows.each do |record_data|
          record = JSON.parse(record_data, symbolize_names: true)
          sk_record = RegisterSourcesSk::Record[**record]
          bods_mapper.process(sk_record)
        end
      end

      def file_processed?(s3_path)
        redis.sismember(NAMESPACE, s3_path)
      end

      def mark_file_complete(s3_path)
        redis.sadd(NAMESPACE, [s3_path])
      end
    end
  end
end
