# frozen_string_literal: true

module JsonAPIObjectMapper
  module Parser
    class IncludedResources
      extend Forwardable

      attr_reader :resource
      def_delegator :@resource, :empty?

      def self.load(included_resources)
        return included_resources if included_resources.is_a?(self)
        new included_resources
      end

      def initialize(included_resources = [])
        included_resources ||= []
        @resource = included_resources.each_with_object({}) do |include, hash|
          hash[format_key(include)] = include["attributes"]
        end

        freeze
      end

      def fetch(relationship, fallback = nil)
        @resource.fetch(format_key(relationship), fallback || relationship)
      end

      def included?(relationship)
        @resource.key?(format_key(relationship))
      end

      def format_key(relationship)
        "#{relationship['type']}:#{relationship['id']}"
      end
    end
  end
end
