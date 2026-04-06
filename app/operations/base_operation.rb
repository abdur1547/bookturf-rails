# frozen_string_literal: true

require "dry/monads"
require "dry/validation"

class BaseOperation
  include Dry::Monads[:result, :do]

  class Result
    attr_reader :success, :value, :errors

    def initialize(success:, value: nil, errors: nil)
      @success = success
      @value = value
      @errors = errors
    end
  end

  class << self
    # Define an inline contract for parameter validation
    # @yield Block containing dry-validation schema definition
    def contract(&block)
      @contract_class = Class.new(Dry::Validation::Contract, &block)
    end

    # Set an external contract class for parameter validation
    # @param contract_class [Class] A Dry::Validation::Contract subclass
    def contract_class(contract_class = nil)
      if contract_class
        @contract_class = contract_class
      else
        @contract_class
      end
    end

    # Execute the operation with automatic validation
    # Accepts any number of arguments and forwards them to the instance
    def call(*args)
      new.execute(*args)
    end
  end

  # Execute the operation with validation and error handling
  # Accepts any number of arguments and forwards them to call
  def execute(*args)
    # If contract is defined, validate only the first argument (params)
    if self.class.contract_class && args.any?
      validation_result = validate_params(args[0])
      return wrap_result(Failure(validation_result.errors.to_h)) if validation_result.failure?
    end

    # Call the main operation logic with all arguments
    result = call(*args)
    wrap_result(result)
    # rescue StandardError => e
    #   # Catch any unhandled exceptions and return as failure
    #   wrap_result(Failure(error: e.message, exception: e))
  end

  # Main operation logic - must be implemented by subclasses
  # @param params [Hash] Validated parameters
  # @return [Dry::Monads::Result] Success or Failure monad
  def call(params)
    raise NotImplementedError, "#{self.class} must implement #call method"
  end

  private

  # Validate parameters using the defined contract
  # @param params [Hash] Parameters to validate
  # @return [Dry::Validation::Result] Validation result
  def validate_params(params)
    contract = self.class.contract_class.new
    contract.call(params)
  end

  # Wrap a Dry::Monads::Result into BaseOperation::Result
  # @param monad_result [Dry::Monads::Result] Result monad
  # @return [Result] Wrapped result
  def wrap_result(monad_result)
    case monad_result
    when Dry::Monads::Success
      Result.new(success: true, value: monad_result.value!)
    when Dry::Monads::Failure
      failure_value = monad_result.failure
      Result.new(success: false, errors: failure_value)
    else
      # Fallback for unexpected result types
      Result.new(success: true, value: monad_result)
    end
  end
end
