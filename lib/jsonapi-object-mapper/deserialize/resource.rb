# frozen_string_literal: true

require "jsonapi-object-mapper/deserialize/dsl"
require "jsonapi-object-mapper/deserialize/collection"
require "jsonapi-object-mapper/parser/errors"

module JsonAPIObjectMapper
  module Deserialize
    class Resource
      include JsonAPIObjectMapper::Parser::Errors
      extend DSL

      class << self
        attr_accessor :rel_has_one_blocks, :rel_has_many_blocks, :rel_options, :attr_blocks, :id_block, :type_block
      end
      instance_variable_set("@attr_blocks", {})
      instance_variable_set("@rel_has_one_blocks", {})
      instance_variable_set("@rel_has_many_blocks", {})
      instance_variable_set("@rel_options", {})

      def self.inherited(klass)
        super
        klass.instance_variable_set("@attr_blocks", attr_blocks.dup)
        klass.instance_variable_set("@rel_has_one_blocks", rel_has_one_blocks.dup)
        klass.instance_variable_set("@rel_has_many_blocks", rel_has_many_blocks.dup)
        klass.instance_variable_set("@rel_options", rel_options.dup)
        klass.instance_variable_set("@id_block", id_block)
        klass.instance_variable_set("@type_block", type_block)
      end

      def self.call(document)
        load(document)
      end

      def self.load(document)
        parser = JsonAPIObjectMapper::Parser::Document.new(document)
        if parser.document["data"].is_a?(Array) || parser.invalid?
          Collection.new(parser, klass: self)
        else
          new(parser)
        end
      end

      def initialize(parser, document: nil)
        super()
        raise InvalidParser unless parser.is_a?(JsonAPIObjectMapper::Parser::Document)
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
        deserialize_has_one_relationships!
        deserialize_has_many_relationships!
      end

      def deserialize_id_type!
        # Initialize ID and Type attribute blocks if one does not exist
        self.class.id   unless self.class.id_block
        self.class.type unless self.class.type_block

        assign_attribute("id", self.class.id_block.call(@id))
        assign_attribute("type", self.class.type_block.call(@type))
      end

      def deserialize_attributes!
        return if @attributes.empty?
        @attributes.each_pair(&method(:new_attribute))
      end

      def deserialize_has_one_relationships!
        return if @relationships.empty?
        @relationships.each_pair(&method(:new_has_one_relationship))
      end

      def deserialize_has_many_relationships!
        return if @relationships.empty?
        @relationships.each_pair(&method(:new_has_many_relationship))
      end

      def new_attribute(attr_name, attr_value)
        return unless include_attribute?(attr_name)
        assign_attribute(attr_name, attr_value)
      end

      def new_has_one_relationship(rel_type, rel_value)
        return unless include_has_one_relationship?(rel_type)
        assign_has_one_relationship(rel_type, rel_value["data"])
      end

      def new_has_many_relationship(rel_type, rel_value)
        return unless include_has_many_relationship?(rel_type)
        assign_has_many_relationship(rel_type, rel_value["data"])
      end
    end
  end
end
