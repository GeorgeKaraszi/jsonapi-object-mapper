# frozen_string_literal: true

require "spec_helper"

module JsonAPIObjectMapper
  module Deserialize # rubocop:disable Metrics/ModuleLength
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

      describe ".has_one Relationship" do
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

        context "Has one included Resource" do
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
            expect(actual.photo).to include("attributes" => { "image" => "good_day_sir.jpg" })
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

          it "Should assign attributes that exist from the included resource" do
            photo_klass = Class.new(described_class) do
              attribute :image
            end

            core_klass = Class.new(described_class) do
              has_one :photo, embed_with: photo_klass
            end

            actual = core_klass.load(payload)
            expect(actual.photo).to be_a(photo_klass)
            expect(actual.photo.id).to eq("1")
            expect(actual.photo.type).to eq("photo")
            expect(actual.photo.image).to be_nil
          end
        end
      end

      describe ".has_many Relationships" do
        let(:payload) do
          {
            "relationships" => {
              "photos" => {
                "data" => [
                  { "type" => "photo", "id" => "1" },
                  { "type" => "photo", "id" => "99" },
                ],
              },
            },
          }
        end

        context "Has many included resources" do
          let(:included_payload) do
            payload.merge(
              "included" => [
                {
                  "id" => "1",
                  "type" => "photo",
                  "attributes" => { "image" => "good_day_sir.jpg" },
                },
                {
                  "id" => "99",
                  "type" => "photo",
                  "attributes" => { "image" => "i_said_good_day!.jpg" },
                },
              ],
            )
          end

          it "Should store a collection of included values" do
            klass = Class.new(described_class) do
              has_many :photos
            end

            actual = klass.load(included_payload)
            expect(actual.photos).to be_a(Array)
            expect(actual.photos.first["id"]).to eq("1")
            expect(actual.photos.first["type"]).to eq("photo")

            expect(actual.photos.last["id"]).to eq("99")
            expect(actual.photos.last["type"]).to eq("photo")
          end

          it "Should resolve the embed_with option to a collection of parsed results" do
            photo_klass = Class.new(described_class)
            klass       = Class.new(described_class) do
              has_many :photos, embed_with: photo_klass
            end

            actual = klass.load(included_payload)
            expect(actual.photos).to be_a(Collection)
            expect(actual.photos[0].id).to eq("1")
            expect(actual.photos[1].id).to eq("99")
          end
        end

        context "Has no included resources" do
          it "Should set the hash of the unresolved type" do
            klass = Class.new(described_class) do
              has_many :photos
            end

            actual = klass.load(payload)
            expect(actual.photos).to be_a(Array)
            expect(actual.photos.first).to be_a(Hash)
            expect(actual.photos.first["id"]).to eq("1")
            expect(actual.photos.last["id"]).to eq("99")
          end
        end
      end

      describe "Links" do
        let(:foo_bar_klass) { Class.new(described_class) }
        subject { foo_bar_klass.load(payload).links }

        it_behaves_like "it contains links"

        context "Response does not contain links" do
          let(:payload) { {} }
          it { is_expected.to be_nil }
        end
      end
    end
  end
end
