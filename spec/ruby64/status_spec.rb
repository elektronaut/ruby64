# frozen_string_literal: true

require "spec_helper"

describe Ruby64::Status do
  subject(:status) { described_class.new(flags) }

  let(:flags) do
    [:foo, :bar, nil, :baz]
  end

  specify { expect(status.value).to eq(0x0) }

  it "defines setter methods" do
    status.foo = true
    status.baz = true
    expect(status.value).to eq(0x09)
  end

  it "defines boolean methods" do
    status.baz = true
    expect(status.baz?).to be(true)
  end

  it "defines accessor methods" do
    status.baz = true
    expect(status.baz).to be(1)
  end
end
