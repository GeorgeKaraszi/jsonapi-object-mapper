# frozen_string_literal: true

require "jsonapi-object-mapper/parser/included_resources"
require "jsonapi-object-mapper/parser/errors"

module JsonAPIObjectMapper
  module Parser
    class Document
      include Errors

      attr_reader :document, :includes, :links

      def initialize(document)
        parsed_document = (document.is_a?(String) ? ::Oj.load(document) : document)
        @includes       = IncludedResources.load(parsed_document.delete("included"))
        @links          = deserialize_links(parsed_document.delete("links")).freeze
        @document       = parsed_document.freeze
        @errors         = deserialize_errors!.freeze
        freeze
      end

      def document_data
        @document["data"] || @document
      end

      def contains_data_array?
        document_data.is_a?(Array)
      end

      def deserialize_errors!
        return [] unless @document.key?("errors")
        Set.new(@document["errors"]) { |error| OpenStruct.new(error) }
      end

      def deserialize_links(links)
        links&.each_with_object(OpenStruct.new) do |(key, value), struct|
          struct[key.to_s.tr("-", "_")] = value
        end
      end
    end
  end
end
