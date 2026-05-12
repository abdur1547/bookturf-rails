module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication

    before_action :require_super_admin!

    private

    def require_super_admin!
      unless Current.user&.super_admin?
        flash[:alert] = "Access denied. Super admin privileges required."
        redirect_to root_path
      end
    end
  end
end
