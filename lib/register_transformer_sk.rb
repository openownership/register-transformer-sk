# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/json'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/time'

require_relative 'register_transformer_sk/version'

Time.zone = 'UTC'

module RegisterTransformerSk
  class Error < StandardError; end
end
