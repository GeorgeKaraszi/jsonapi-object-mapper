# frozen_string_literal: true

require "spec_helper"

shared_examples_for "it contains links" do
  let(:payload_links) do
    {
      "links" => {
        "total-pages" => 14,
        "self"        => "https://some-random-api.com/search?name=me?page=2",
        "first"       => "https://some-random-api.com/search?name=me?page=1",
        "last"        => "https://some-random-api.com/search?name=me?page=14",
        "prev"        => "https://some-random-api.com/search?name=me?page=1",
        "next"        => "https://some-random-api.com/search?name=me?page=3",
      },
    }
  end

  let(:payload) { payload_links }

  it { is_expected.to be_a(OpenStruct).and(be_frozen) }
  its(:total_pages) { is_expected.to eq(14) }
  its(:self)        { is_expected.to eq("https://some-random-api.com/search?name=me?page=2") }
  its(:first)       { is_expected.to eq("https://some-random-api.com/search?name=me?page=1") }
  its(:last)        { is_expected.to eq("https://some-random-api.com/search?name=me?page=14") }
  its(:prev)        { is_expected.to eq("https://some-random-api.com/search?name=me?page=1") }
  its(:next)        { is_expected.to eq("https://some-random-api.com/search?name=me?page=3") }
end
