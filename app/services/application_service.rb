# frozen_string_literal: true

# Base class for all service objects.
# Provides a standard interface with .call class method and Result struct.
class ApplicationService
  Result = Data.define(:success, :data, :errors) do
    def initialize(success: false, data: nil, errors: [])
      super(success: success, data: data, errors: errors)
    end

    def success?
      success
    end
  end

  def self.call(...)
    new(...).call
  end
end
