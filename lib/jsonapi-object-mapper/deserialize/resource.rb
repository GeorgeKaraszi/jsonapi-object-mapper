# frozen_string_literal: true

require "jsonapi-object-mapper/deserialize/dsl"
require "jsonapi-object-mapper/deserialize/collection"
require "jsonapi-object-mapper/parser/errors"

module JsonAPIObjectMapper
  module Deserialize
    class Resource
      include JsonAPIObjectMapper::Parser::Errors
      extend DSL

      attr_reader :links

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
        if parser.contains_data_array? || parser.invalid?
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
          @links         = parser_links(parser)
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
        document.nil? ? parser.document_data : (document["data"] || document)
      end

      def parser_links(parser)
        parser.links unless parser.contains_data_array?
      end

      def deserialize!
        deserialize_id_type!
        deserialize_attributes!
        deserialize_relationships!
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

      def deserialize_relationships!
        return if @relationships.empty?
        @relationships.each_pair(&method(:new_relationship))
      end

      def new_attribute(attr_name, attr_value)
        return unless attribute_defined?(attr_name)
        assign_attribute(attr_name, attr_value)
      end

      def new_relationship(rel_type, rel_value)
        if has_one_defined?(rel_type)
          assign_has_one_relationship(rel_type, rel_value["data"])
        elsif has_many_defined?(rel_type)
          assign_has_many_relationship(rel_type, rel_value["data"])
        end
      end
    end
  end
end
