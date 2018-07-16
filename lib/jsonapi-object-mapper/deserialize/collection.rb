# frozen_string_literal: true

require "jsonapi-object-mapper/parser/errors"
extend Forwardable

module JsonAPIObjectMapper
  module Deserialize
    class Collection
      extend Forwardable
      include Enumerable
      include JsonAPIObjectMapper::Parser::Errors

      attr_accessor :collection_data

      def_delegators :@collection_data, :first, :last, :[]

      def initialize(parser, klass:)
        raise InvalidResource unless klass.is_a?(Class)
        raise InvalidParser   unless parser.is_a?(JsonAPIObjectMapper::Parser::Document)
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

      def to_hash
        @collection_data.map(&:to_hash)
      end

      def each
        @collection_data.each do |data|
          yield data
        end
      end
    end
  end
end
