# frozen_string_literal: true

require "jsonapi-object-mapper/parser/included_resources"
require "jsonapi-object-mapper/parser/errors"

module JsonAPIObjectMapper
  module Parser
    class Document
      include Errors

      attr_accessor :document, :includes

      def initialize(document)
        @document = document.is_a?(Hash) ? document : ::Oj.load(document)
        @includes = IncludedResources.load(@document["included"])
        @errors   = deserialize_errors!.freeze
        freeze
      end

      def deserialize_errors!
        return [] unless @document.key?("errors")
        Set.new(@document["errors"]) { |error| OpenStruct.new(error) }
      end
    end
  end
end
