# frozen_string_literal: true

module JsonAPIObjectMapper
  module Deserialize
    module DSL
      DEFAULT_ID_BLOCK      = proc { |id| id }
      DEFAULT_TYPE_BLOCK    = proc { |type| type }
      DEFAULT_ATTR_BLOCK    = proc { |value| value }
      DEFAULT_HAS_ONE_BLOCK = proc { |value| value }

      def self.extended(klass)
        klass.include ClassMethods
      end

      def id(&block)
        self.id_block = block || DEFAULT_ID_BLOCK
        define_method(:id) { fetch_attribute(:id) }
      end

      def type(&block)
        self.type_block = block || DEFAULT_TYPE_BLOCK
        define_method(:type) { fetch_attribute(:type) }
      end

      def attribute(attribute_name, &block)
        attr_blocks[attribute_name.to_s] = block || DEFAULT_ATTR_BLOCK
        define_method(attribute_name.to_sym) { fetch_attribute(attribute_name) }
      end

      def attributes(*attributes_names)
        attributes_names.each(&method(:attribute))
      end

      def has_one(relationship_name, embed_with: nil, &block) # rubocop:disable Naming/PredicateName
        rel_blocks[relationship_name.to_s]  = block || DEFAULT_HAS_ONE_BLOCK
        rel_options[relationship_name.to_s] = embed_with unless embed_with.nil?
        define_method(relationship_name.to_sym) { fetch_relationship(relationship_name) }
      end
      alias has_many has_one
      alias belongs_to has_one

      module ClassMethods
        def initialize(*args)
          @_class_attributes    = {}
          @_class_relationships = {}
          super
        end

        def to_hash
          hashed_relationships = @_class_relationships.map do |key, value|
            { key => value.respond_to?(:to_hash) ? value.to_hash : value }
          end
          [@_class_attributes, *hashed_relationships].reduce({}, :merge)
        end
        alias to_h to_hash

        def to_s
          to_hash.to_s
        end

        protected

        def fetch_attribute(key)
          @_class_attributes[key.to_s]
        end

        def fetch_relationship(key)
          @_class_relationships[key.to_s]
        end

        def assign_attribute(key, value)
          block = self.class.attr_blocks[key.to_s] || DEFAULT_ATTR_BLOCK
          @_class_attributes[key.to_s] = block.call(value)
        end

        def assign_relationship(key, value)
          block             = self.class.rel_blocks[key.to_s] || DEFAULT_ATTR_BLOCK
          rel_embed_class   = self.class.rel_options[key.to_s]
          rel_value         = @includes.fetch(value)

          @_class_relationships[key.to_s] =
            if rel_value != value && rel_embed_class.respond_to?(:embed!)
              block.call(rel_embed_class.embed!(rel_value))
            else
              block.call(rel_value)
            end
        end

        def include_attribute?(attribute_name)
          self.class.attr_blocks.key?(attribute_name)
        end

        def include_relationship?(rel_name)
          self.class.rel_blocks.key?(rel_name)
        end
      end
    end
  end
end
