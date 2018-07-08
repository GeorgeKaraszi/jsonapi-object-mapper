# frozen_string_literal: true

require "spec_helper"

module JsonAPIObjectMapper
  module Deserialize
    RSpec.describe Resource do
      describe "Attributes" do
        let(:payload) do
          {
            "attributes" => {
              "foo" => "bar",
              "baz" => "nas",
            },
          }
        end

        it "Generates mappings for defined attributes" do
          klass = Class.new(described_class) do
            attribute :foo
            attribute :baz
          end

          actual = klass.call(payload)
          expect(actual.foo).to eq("bar")
          expect(actual.baz).to eq("nas")
        end

        it "Generates mappings for defined attributes with block modifications" do
          klass = Class.new(described_class) do
            attribute :foo
            attribute :baz do |_attr_value|
              "THIS IS THE REAL DEAL!"
            end
          end

          actual = klass.call(payload)
          expect(actual.baz).to eq("THIS IS THE REAL DEAL!")
        end
      end

      describe "Relationships" do
        let(:payload) do
          {
            "relationships" => {
              "photo" => {
                "data" => {
                  "type" => "photo",
                  "id" => "1",
                },
              },
            },
          }
        end

        context "Has included Resource" do
          let(:included_payload) do
            payload.merge(
              "included" => [
                {
                  "id" => "1",
                  "type" => "photo",
                  "attributes" => { "image" => "good_day_sir.jpg" },
                },
              ],
            )
          end

          it "Should embed the included resource into the relationship" do
            klass = Class.new(described_class) do
              has_one :photo
            end

            actual = klass.call(included_payload)
            expect(actual.photo).to eq("image" => "good_day_sir.jpg")
          end

          it "Should Resolve and decode the resource as the embedded relationship class" do
            photo_klass = Class.new(described_class) do
              attribute :image
            end

            core_klass = Class.new(described_class) do
              has_one :photo, embed_with: photo_klass
            end

            actual = core_klass.call(included_payload)
            expect(actual.photo).to be_a(photo_klass)
            expect(actual.photo.image).to eq("good_day_sir.jpg")
          end
        end

        context "Does not include Resource" do
          it "Should only contain basic relationship data" do
            klass = Class.new(described_class) do
              has_one :photo
            end

            actual = klass.call(payload)
            expect(actual.photo).to eq("id" => "1", "type" => "photo")
          end

          it "Should set the default relationship values if no includes can be found" do
            photo_klass = Class.new(described_class) do
              attribute :image
            end

            core_klass = Class.new(described_class) do
              has_one :photo, embed_with: photo_klass
            end

            actual = core_klass.call(payload)
            expect(actual.photo).to be_a(Hash)
            expect(actual.photo).to eq("id" => "1", "type" => "photo")
          end
        end
      end
    end
  end
end
