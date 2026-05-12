class ImpersonationsController < ApplicationController
  def destroy
    stop_impersonating
    redirect_to admin_users_path, notice: "Stopped impersonating. Welcome back!"
  end
end
