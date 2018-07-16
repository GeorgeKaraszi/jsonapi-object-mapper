# frozen_string_literal: true

module JsonAPIObjectMapper
  module Deserialize
    module DSL
      DEFAULT_BLOCK  = proc { |value| value }
      HAS_MANY_BLOCK = proc { |values| values.is_a?(Collection) ? values : Array(values) }

      def self.extended(klass)
        klass.include ClassMethods
      end

      def id(&block)
        self.id_block = block || DEFAULT_BLOCK
        define_method(:id) { fetch_attribute(:id) }
      end

      def type(&block)
        self.type_block = block || DEFAULT_BLOCK
        define_method(:type) { fetch_attribute(:type) }
      end

      def attribute(attribute_name, &block)
        attr_blocks[attribute_name.to_s] = block || DEFAULT_BLOCK
        define_method(attribute_name.to_sym) { fetch_attribute(attribute_name) }
      end

      def attributes(*attributes_names)
        attributes_names.each(&method(:attribute))
      end

      def has_one(relationship_name, **options, &block) # rubocop:disable Naming/PredicateName
        rel_options_process!(relationship_name, options)
        rel_has_one_blocks[relationship_name.to_s] = block || DEFAULT_BLOCK
        define_method(relationship_name.to_sym) { fetch_relationship(relationship_name) }
      end
      alias belongs_to has_one

      def has_many(relationship_name, **options, &block) # rubocop:disable Naming/PredicateName
        rel_options_process!(relationship_name, options)
        rel_has_many_blocks[relationship_name.to_s] = block || HAS_MANY_BLOCK
        define_method(relationship_name.to_sym) { fetch_relationship(relationship_name) }
      end

      def kind_of_resource?(klass)
        !klass.nil? && klass < Resource
      end

      private

      def rel_options_process!(relationship_name, **options)
        embed_klass = options.delete(:embed_with)
        return if embed_klass.nil?

        embed_klass = embed_klass.is_a?(String) ? Kernel.const_get(embed_klass) : embed_klass
        if kind_of_resource?(embed_klass)
          rel_options[relationship_name.to_s] = { embed_with: embed_klass }
        else
          raise InvalidEmbedKlass
        end
      rescue NameError # Rescue from `Kernel.const_get/1`
        raise InvalidEmbedKlass
      end

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
          block = self.class.attr_blocks.fetch(key.to_s, DEFAULT_BLOCK)
          @_class_attributes[key.to_s] = block.call(value)
        end

        def assign_has_one_relationship(key, value)
          key                        = key.to_s
          block                      = self.class.rel_has_one_blocks.fetch(key, DEFAULT_BLOCK)
          rel_embed_class            = self.class.rel_options.dig(key, :embed_with)
          rel_value                  = embed!(rel_embed_class, @includes.fetch(value))
          @_class_relationships[key] = block.call(rel_value)
        end

        def assign_has_many_relationship(key, values)
          key                        = key.to_s
          block                      = self.class.rel_has_many_blocks.fetch(key, HAS_MANY_BLOCK)
          rel_embed_class            = self.class.rel_options.dig(key, :embed_with)
          rel_values                 = values.map { |value| @includes.fetch(value) }
          @_class_relationships[key] = block.call(embed!(rel_embed_class, rel_values))
        end

        def include_attribute?(attribute_name)
          self.class.attr_blocks.key?(attribute_name)
        end

        def include_has_one_relationship?(rel_name)
          self.class.rel_has_one_blocks.key?(rel_name)
        end

        def include_has_many_relationship?(rel_name)
          self.class.rel_has_many_blocks.key?(rel_name)
        end

        def kind_of_resource?(rel_embed_class)
          self.class.kind_of_resource?(rel_embed_class)
        end

        def embed!(rel_embed_class, attributes)
          return attributes unless self.class.kind_of_resource?(rel_embed_class)
          rel_embed_class.load("data" => attributes)
        end
      end
    end
  end
end
