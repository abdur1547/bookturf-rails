# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |exception|
      case exception.class.name
      when ActiveRecord::RecordInvalid.name
        unprocessable_entity(exception.message)
      when ::Auth::InvalidTokenError.name, ::Auth::MissingTokenError.name
        forbidden_response(exception.message)
      when ::Auth::UnauthorizedError.name
        unauthorized_response
      else
        process_standard_error(exception)
      end
    end
  end

  private

  def success_response(data = {}, status: :ok)
    render json: { success: true, data: }, status:
  end

  def process_standard_error(exception)
    render json: { success: false, errors: [ exception.message ] }, status: :internal_server_error
  end

  def unauthorized_response(reason = "You are unauthorized to view this resource")
    render json: { success: false, errors: [ reason ] }, status: :unauthorized
  end

  def not_found_response(reason = "The requested resource does not exist")
    render json: { success: false, errors: [ reason ] }, status: :not_found
  end

  def unprocessable_entity(reason)
    render json: { success: false, errors: reason }, status: :unprocessable_entity
  end

  def forbidden_response(reason = "forbidden")
    render json: { success: false, errors: [ reason ] }, status: :forbidden
  end
end
