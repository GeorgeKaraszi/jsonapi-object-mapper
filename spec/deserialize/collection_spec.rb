# frozen_string_literal: true

require "spec_helper"

module JsonAPIObjectMapper
  module Deserialize
    RSpec.describe Collection do
      let(:parser) { JsonAPIObjectMapper::Parser::Document.new(payload) }
      let(:payload) { {} }

      describe ".new" do
        context "Rising Exceptions" do
          it "is expected to raise an error if the resource isn't a class object" do
            expect { described_class.new(nil, klass: "Class") }.to raise_error(InvalidResource)
          end

          it "is expected to raise an error if the parser isn't a parsed json document" do
            expect { described_class.new({}, { klass: Class }) }.to raise_error(InvalidParser)
          end
        end

        context "Creating a collection of resources" do
          let(:payload) do
            {
              "data" => [
                {
                  "id" => "1",
                  "type" => "foobar",
                  "attributes" => {
                    "name" => "Bert",
                  },
                },
                {
                  "id" => "2",
                  "type" => "foobar",
                  "attributes" => {
                    "name" => "Johnson",
                  },
                },
              ],
            }
          end
          it "Should collect all resources into a enumerable resource" do
            foobar_klass = Class.new(JsonAPIObjectMapper::Deserialize::Resource) do
              attribute :name
            end

            result = described_class.new(parser, klass: foobar_klass)
            expect(result.valid?).to be_truthy
            expect(result.count).to eq(2)
            expect(result.map(&:name)).to eq(%w[Bert Johnson])
          end
        end

        context "Results containing errors" do
          let(:payload) do
            {
              "errors" => [
                {
                  "title" => "Invalid name",
                  "detail" => "Look like foobar to me",
                  "source" => {
                    "pointer" => "name",
                  },
                },
              ],
            }
          end

          it "Should return as an invalid or error document" do
            result = described_class.new(parser, klass: Class.new)
            expect(result).to be_invalid
          end

          it "Should contain all error responses the in #errors field" do
            result = described_class.new(parser, klass: Class.new).errors.first
            expect(result.title).to eq("Invalid name")
            expect(result.detail).to eq("Look like foobar to me")
            expect(result.source).to include("pointer" => "name")
          end
        end

        context "Links" do
          let(:foo_bar_klass) { Class.new(JsonAPIObjectMapper::Deserialize::Resource) }
          subject { described_class.new(parser, klass: foo_bar_klass).links }

          context "Results do not include links" do
            it { is_expected.to be_nil }
          end

          it_behaves_like "it contains links" do
            let!(:payload) { payload_links.merge("data" => [{ "id" => "1", "type" => "foobar" }]) }

            it "Should not include links in the children of data resources" do
              results = described_class.new(parser, klass: foo_bar_klass)
              expect(results.first.id).to eq("1")
              expect(results.first.links).to be_nil
            end
          end
        end
      end
    end
  end
end
