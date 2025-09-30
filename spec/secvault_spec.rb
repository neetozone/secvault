# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/secvault/version"

# Define minimal module for testing without Rails dependencies
module Secvault
  class Error < StandardError; end
end

RSpec.describe Secvault do
  describe "VERSION" do
    it "has a version number" do
      expect(Secvault::VERSION).not_to be_nil
      expect(Secvault::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
      expect(Secvault::VERSION).to eq("3.3.0")
    end
  end

  describe "Error" do
    it "defines base Error class" do
      expect(Secvault::Error).to be < StandardError
    end
  end
end
