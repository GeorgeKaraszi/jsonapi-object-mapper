# frozen_string_literal: true

require "jsonapi-object-mapper/parser/errors"

module JsonAPIObjectMapper
  module Deserializer
    class Collection
      include Enumerable
      include JsonAPIObjectMapper::Parser::Errors

      attr_accessor :collection_data

      def initialize(parser, klass:)
        raise ArgumentError, "Must provide a valid resource klass" unless klass.is_a?(Class)
        raise ArgumentError, "Must provide a parsed document" unless parser.is_a?(JsonAPIObjectMapper::Parser::Document)
        @errors            = parser.errors
        @collection_data   =
          if document_invalid?
            []
          else
            Array(parser.document["data"]).map do |doc|
              klass.new(parser, document: doc)
            end
          end.freeze

        freeze
      end

      def each
        @collection_data.each do |data|
          yield data
        end
      end
    end
  end
end
