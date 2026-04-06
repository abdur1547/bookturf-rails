# frozen_string_literal: true

# require_relative 'service_result'

class BaseService
  def self.call(*args, **kwargs, &block)
    new.call(*args, **kwargs, &block)
  end

  def call(*_args, **_kwargs)
    raise NotImplementedError, "#{self.class} must implement #call method"
  end

  private

  def success(data = nil)
    ServiceResult.success(data)
  end

  def failure(error)
    ServiceResult.failure(error)
  end
end
