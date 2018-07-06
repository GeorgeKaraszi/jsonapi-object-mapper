# frozen_string_literal: true

require "jsonapi-object-mapper/deserializer/dsl"
require "jsonapi-object-mapper/deserializer/collection"
require "jsonapi-object-mapper/parser/errors"

module JsonAPIObjectMapper
  module Deserializer
    class Resource
      include JsonAPIObjectMapper::Parser::Errors
      extend DSL

      class << self
        attr_accessor :rel_blocks, :rel_options, :attr_blocks, :id_block, :type_block
      end
      instance_variable_set("@attr_blocks", {})
      instance_variable_set("@rel_blocks", {})
      instance_variable_set("@rel_options", {})

      def self.inherited(klass)
        super
        klass.instance_variable_set("@attr_blocks", attr_blocks.dup)
        klass.instance_variable_set("@rel_blocks", rel_blocks.dup)
        klass.instance_variable_set("@rel_options", rel_options.dup)
        klass.instance_variable_set("@id_block", id_block)
        klass.instance_variable_set("@type_block", type_block)
      end

      def self.call(document)
        parser = JsonAPIObjectMapper::Parser::Document.new(document)
        if parser.document["data"].is_a?(Array) || parser.invalid?
          Collection.new(parser, klass: self)
        else
          new(parser)
        end
      end

      def self.embed!(attributes)
        parser = JsonAPIObjectMapper::Parser::Document.new("attributes" => attributes)
        new(parser)
      end

      def initialize(parser, document: nil)
        super()
        raise ArgumentError, "Must provide a parsed document" unless parser.is_a?(JsonAPIObjectMapper::Parser::Document)
        @errors = parser.errors

        if document_valid?
          @includes      = parser.includes
          @data          = document_data(parser, document)
          @id            = @data["id"]
          @type          = @data["type"]
          @attributes    = @data.fetch("attributes", {})
          @relationships = @data.fetch("relationships", {})
          deserialize!
        end

        freeze
      end

      def each
        yield self
      end

      private

      def document_data(parser, document)
        document.nil? ? (parser.document["data"] || parser.document) : (document["data"] || document)
      end

      def deserialize!
        deserialize_id_type!
        deserialize_attributes!
        deserialize_relationships!
      end

      def deserialize_id_type!
        assign_attribute("id", self.class.id_block.call(@id))       if self.class.id_block
        assign_attribute("type", self.class.type_block.call(@type)) if self.class.type_block
      end

      def deserialize_attributes!
        return if @attributes.empty?
        @attributes.each_pair(&method(:initialize_attribute))
      end

      def deserialize_relationships!
        return if @relationships.empty?
        @relationships.each_pair(&method(:initialize_relationship))
      end

      def initialize_attribute(attr_name, attr_value)
        return unless include_attribute?(attr_name)
        assign_attribute(attr_name, attr_value)
      end

      def initialize_relationship(rel_type, rel_value)
        return unless include_relationship?(rel_type)
        assign_relationship(rel_type, rel_value["data"])
      end
    end
  end
end
