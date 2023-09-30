# frozen_string_literal: true

require 'register_common/adapters/s3_adapter'
require 'register_transformer_sk/config/settings'

module RegisterTransformerSk
  module Config
    module Adapters
      S3_ADAPTER = RegisterCommon::Adapters::S3Adapter.new(credentials: AWS_CREDENTIALS)
    end
  end
end
