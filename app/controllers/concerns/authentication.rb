module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :impersonating?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end

    def impersonating?
      cookies.signed[:impersonator_session_id].present?
    end

    def start_impersonating(user)
      cookies.signed.permanent[:impersonator_session_id] = {
        value: Current.session.id,
        httponly: true,
        same_site: :lax
      }
      start_new_session_for(user)
    end

    def stop_impersonating
      admin_session_id = cookies.signed[:impersonator_session_id]
      cookies.delete(:impersonator_session_id)
      Current.session.destroy

      if (admin_session = Session.find_by(id: admin_session_id))
        Current.session = admin_session
        cookies.signed.permanent[:session_id] = { value: admin_session.id, httponly: true, same_site: :lax }
      else
        cookies.delete(:session_id)
      end
    end
end
