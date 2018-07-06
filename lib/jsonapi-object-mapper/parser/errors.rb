# frozen_string_literal: true

module JsonAPIObjectMapper
  module Parser
    module Errors
      attr_accessor :errors

      def valid?
        @errors.nil? || @errors.empty?
      end
      alias document_valid? valid?

      def invalid?
        !valid?
      end
      alias errors? invalid?
      alias document_invalid? invalid?
    end
  end
end
