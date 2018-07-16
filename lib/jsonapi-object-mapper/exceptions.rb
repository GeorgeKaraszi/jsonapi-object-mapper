# frozen_string_literal: true

module JsonAPIObjectMapper
  class InvalidResource < StandardError
    def initialize(msg = nil)
      msg ||= "The deserializer class must be an inherited `JsonAPIObjectMapper::Deserialize::Resource` klass"
      super
    end
  end

  class InvalidParser < StandardError
    def initialize(msg = nil)
      msg ||= "Must provide a parsed `JsonAPIObjectMapper::Parser::Document` klass-document"
      super
    end
  end

  class InvalidEmbedKlass < StandardError
    def initialize(msg = nil)
      msg ||= "The `embed_with: ...` option, must be a inherited `JsonAPIObjectMapper::Deserialize::Resource` klass"
      super
    end
  end
end
