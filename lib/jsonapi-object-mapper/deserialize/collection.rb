# frozen_string_literal: true

require "jsonapi-object-mapper/parser/errors"

module JsonAPIObjectMapper
  module Deserialize
    class Collection
      extend Forwardable
      include Enumerable
      include JsonAPIObjectMapper::Parser::Errors

      attr_reader :collection_data, :links

      def_delegators :@collection_data, :first, :last, :[]

      def initialize(parser, klass:)
        raise InvalidResource unless klass.is_a?(Class)
        raise InvalidParser   unless parser.is_a?(JsonAPIObjectMapper::Parser::Document)
        @errors            = parser.errors
        @links             = parser.links
        @collection_data   =
          if document_invalid?
            []
          else
            Array(parser.document_data).map do |doc|
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

      def inspect
        "#<#{self.class}:0x#{object_id.to_s(16)}, "\
        "@errors=#{@errors.inspect}, "\
        "@links=#{@links.inspect}, "\
        "@data=#{@collection_data.map(&:inspect)}>"\
      end
      alias to_s inspect

      def to_hash
        {}.tap do |hash|
          hash[:data]   = @collection_data.map(&:to_hash)
          hash[:links]  = @links.to_h unless @links.nil?
          hash[:errors] = @errors unless valid?
        end
      end
      alias to_h to_hash
    end
  end
end
