# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServiceResult do
  describe '.success' do
    it 'creates a successful result with data' do
      result = described_class.success('success data')

      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.data).to eq('success data')
      expect(result.error).to be_nil
    end

    it 'creates a successful result without data' do
      result = described_class.success

      expect(result).to be_success
      expect(result.data).to be_nil
      expect(result.error).to be_nil
    end

    it 'accepts complex data objects' do
      data = { user: 'John', id: 123, metadata: { created_at: Time.current } }
      result = described_class.success(data)

      expect(result).to be_success
      expect(result.data).to eq(data)
    end

    it 'accepts arrays as data' do
      data = [ 1, 2, 3, 4, 5 ]
      result = described_class.success(data)

      expect(result).to be_success
      expect(result.data).to eq(data)
    end

    it 'accepts nil as data' do
      result = described_class.success(nil)

      expect(result).to be_success
      expect(result.data).to be_nil
    end
  end

  describe '.failure' do
    it 'creates a failed result with string error' do
      result = described_class.failure('error message')

      expect(result).to be_failure
      expect(result).not_to be_success
      expect(result.error).to eq('error message')
      expect(result.data).to be_nil
    end

    it 'accepts array of errors' do
      errors = [ 'Error 1', 'Error 2', 'Error 3' ]
      result = described_class.failure(errors)

      expect(result).to be_failure
      expect(result.error).to eq(errors)
    end

    it 'accepts hash errors' do
      error_obj = { code: 422, message: 'Validation failed', field: 'email' }
      result = described_class.failure(error_obj)

      expect(result).to be_failure
      expect(result.error).to eq(error_obj)
    end

    it 'accepts exception objects' do
      exception = StandardError.new('Something went wrong')
      result = described_class.failure(exception)

      expect(result).to be_failure
      expect(result.error).to eq(exception)
    end

    it 'accepts nil as error' do
      result = described_class.failure(nil)

      expect(result).to be_failure
      expect(result.error).to be_nil
    end
  end

  describe '#success?' do
    it 'returns true for successful results' do
      result = described_class.success('data')
      expect(result.success?).to be true
    end

    it 'returns false for failed results' do
      result = described_class.failure('error')
      expect(result.success?).to be false
    end
  end

  describe '#failure?' do
    it 'returns true for failed results' do
      result = described_class.failure('error')
      expect(result.failure?).to be true
    end

    it 'returns false for successful results' do
      result = described_class.success('data')
      expect(result.failure?).to be false
    end
  end

  describe '#data' do
    it 'returns data for successful results' do
      result = described_class.success('my data')
      expect(result.data).to eq('my data')
    end

    it 'returns nil for failed results' do
      result = described_class.failure('error')
      expect(result.data).to be_nil
    end
  end

  describe '#error' do
    it 'returns error for failed results' do
      result = described_class.failure('my error')
      expect(result.error).to eq('my error')
    end

    it 'returns nil for successful results' do
      result = described_class.success('data')
      expect(result.error).to be_nil
    end
  end

  describe 'initialization' do
    it 'can be initialized directly' do
      result = described_class.new(success: true, data: 'test', error: nil)

      expect(result).to be_success
      expect(result.data).to eq('test')
    end

    it 'requires success parameter' do
      expect {
        described_class.new(data: 'test')
      }.to raise_error(ArgumentError)
    end
  end

  describe 'immutability' do
    it 'does not allow data to be changed' do
      result = described_class.success('data')

      expect(result).not_to respond_to(:data=)
    end

    it 'does not allow error to be changed' do
      result = described_class.failure('error')

      expect(result).not_to respond_to(:error=)
    end
  end
end
