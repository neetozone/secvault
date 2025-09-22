# frozen_string_literal: true

RSpec.describe Secvault do
  it "has a version number" do
    expect(Secvault::VERSION).not_to be nil
  end

  it "defines error classes" do
    expect(Secvault::Error).to be < StandardError
    expect(Secvault::MissingKeyError).to be < Secvault::Error
    expect(Secvault::InvalidKeyError).to be < Secvault::Error
  end

  describe ".install!" do
    it "does not raise errors when called" do
      expect { Secvault.install! }.not_to raise_error
    end
  end
end
