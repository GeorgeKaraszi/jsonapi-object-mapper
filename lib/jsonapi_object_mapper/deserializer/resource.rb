# frozen_string_literal: true

require "jsonapi_object_mapper/deserializer/dsl"
require "jsonapi_object_mapper/deserializer/included_resources"

module JsonAPIObjectMapper
  module Deserializer
    class Resource
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

      def self.call_collection(document)
        parsed_document = document.is_a?(Hash) ? document : ::Oj.load(document)
        parsed_includes = IncludedResources.load(parsed_document["included"])
        Array(parsed_document["data"]).map { |doc| new(doc, parsed_includes) }
      end

      def self.call(document, parsed_includes = nil)
        parsed_document = document.is_a?(Hash) ? document : ::Oj.load(document)
        parsed_includes ||= IncludedResources.load(parsed_document["included"])
        new(parsed_document["data"], parsed_includes)
      end

      def self.embed!(attributes)
        new("attributes" => attributes)
      end

      def initialize(payload = nil, included = nil)
        super()
        data           = payload || {}
        @id            = data["id"]
        @type          = data["type"]
        @attributes    = data["attributes"] || {}
        @relationships = data["relationships"] || {}
        @includes      = IncludedResources.load(included)
        deserialize!

        freeze
      end

      private

      def deserialize!
        deserialize_id_type!
        deserialize_attributes!
        deserialize_relationships!
      end

      def deserialize_id_type!
        assign_attribute("id", self.class.id_block&.call(@id))
        assign_attribute("type", self.class.type_block&.call(@id))
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
        assign_relationship(rel_type, @includes.fetch(rel_value["data"]))
      end
    end
  end
end
