require_relative 'register_transformer_sk/version'

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/time'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/object/json'

Time.zone='UTC'

module RegisterTransformerSk
  class Error < StandardError; end
end
