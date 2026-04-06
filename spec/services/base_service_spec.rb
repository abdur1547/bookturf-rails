# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseService, type: :service do
  let(:test_service_class) do
    Class.new(BaseService) do
      def call(param1, param2 = nil)
        return failure('param1 is required') if param1.nil?
        return failure('param1 must be positive') if param1.is_a?(Numeric) && param1 <= 0

        success(param1 + (param2 || 0))
      end
    end
  end

  describe '.call' do
    it 'instantiates the service and calls the instance method' do
      result = test_service_class.call(5, 3)

      expect(result).to be_success
      expect(result.data).to eq(8)
    end

    it 'works with single parameter' do
      result = test_service_class.call(10)

      expect(result).to be_success
      expect(result.data).to eq(10)
    end

    it 'returns failure for invalid input' do
      result = test_service_class.call(-5)

      expect(result).to be_failure
      expect(result.error).to eq('param1 must be positive')
    end

    context 'with initialize method for dependency injection' do
      let(:service_with_dependency) do
        Class.new(BaseService) do
          def initialize(multiplier: 2)
            @multiplier = multiplier
          end

          def call(value)
            success(value * @multiplier)
          end
        end
      end

      it 'allows using initialize with instance method' do
        service = service_with_dependency.new(multiplier: 3)
        result = service.call(10)

        expect(result).to be_success
        expect(result.data).to eq(30)
      end

      it 'works with default initialize parameters' do
        service = service_with_dependency.new
        result = service.call(10)

        expect(result).to be_success
        expect(result.data).to eq(20)
      end
    end

    it 'accepts keyword arguments' do
      keyword_service = Class.new(BaseService) do
        def call(value:)
          success(value * 2)
        end
      end

      result = keyword_service.call(value: 10)
      expect(result.data).to eq(20)
    end

    it 'accepts blocks' do
      block_service = Class.new(BaseService) do
        def call(&block)
          result = yield if block_given?
          success(result)
        end
      end

      result = block_service.call { 'block result' }
      expect(result.data).to eq('block result')
    end
  end

  describe '#call' do
    context 'when not implemented in subclass' do
      it 'raises NotImplementedError' do
        service = BaseService.new

        expect { service.call }.to raise_error(
          NotImplementedError,
          'BaseService must implement #call method'
        )
      end
    end

    context 'when implemented in subclass' do
      it 'executes the subclass implementation' do
        service = test_service_class.new
        result = service.call(5, 3)

        expect(result).to be_success
        expect(result.data).to eq(8)
      end
    end
  end

  describe 'ServiceResult object' do
    describe '.success' do
      it 'creates a successful result with data' do
        result = ServiceResult.success('success data')

        expect(result).to be_success
        expect(result).not_to be_failure
        expect(result.data).to eq('success data')
        expect(result.error).to be_nil
      end

      it 'creates a successful result without data' do
        result = ServiceResult.success

        expect(result).to be_success
        expect(result.data).to be_nil
      end
    end

    describe '.failure' do
      it 'creates a failed result with error' do
        result = ServiceResult.failure('error message')

        expect(result).to be_failure
        expect(result).not_to be_success
        expect(result.error).to eq('error message')
        expect(result.data).to be_nil
      end

      it 'accepts complex error objects' do
        error_obj = { code: 422, message: 'Validation failed' }
        result = ServiceResult.failure(error_obj)

        expect(result).to be_failure
        expect(result.error).to eq(error_obj)
      end
    end
  end

  describe 'private helper methods' do
    let(:service) { test_service_class.new }

    describe '#success' do
      it 'returns a successful ServiceResult object' do
        result = service.send(:success, 'data')

        expect(result).to be_a(ServiceResult)
        expect(result).to be_success
        expect(result.data).to eq('data')
      end
    end

    describe '#failure' do
      it 'returns a failed ServiceResult object' do
        result = service.send(:failure, 'error')

        expect(result).to be_a(ServiceResult)
        expect(result).to be_failure
        expect(result.error).to eq('error')
      end
    end
  end

  describe 'real-world example' do
    let(:user_registration_service) do
      Class.new(BaseService) do
        def call(email:, password:)
          return failure('Email is required') if email.blank?
          return failure('Password must be at least 8 characters') if password.to_s.length < 8

          # Simulate user creation
          user = { id: 1, email: email, created_at: Time.current }
          success(user)
        rescue StandardError => e
          failure("Registration failed: #{e.message}")
        end
      end
    end

    it 'handles successful registration' do
      result = user_registration_service.call(
        email: 'test@example.com',
        password: 'password123'
      )

      expect(result).to be_success
      expect(result.data[:email]).to eq('test@example.com')
    end

    it 'handles validation errors' do
      result = user_registration_service.call(email: '', password: '123')

      expect(result).to be_failure
      expect(result.error).to eq('Email is required')
    end

    it 'handles exceptions' do
      failing_service = Class.new(BaseService) do
        def call
          raise StandardError, 'Something went wrong'
        rescue StandardError => e
          failure(e.message)
        end
      end

      result = failing_service.call

      expect(result).to be_failure
      expect(result.error).to eq('Something went wrong')
    end
  end
end
