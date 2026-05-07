# frozen_string_literal: true

class StaffMailer < ApplicationMailer
  def invitation(user, venue, temp_password)
    @user = user
    @venue = venue
    @temp_password = temp_password
    @login_url = ENV.fetch("FRONTEND_URL", "https://bookturf.app") + "/login"

    mail(
      to: @user.email,
      subject: "You've been added to #{@venue.name}"
    )
  end

  def access_removed(user, venue)
    @user = user
    @venue = venue

    mail(
      to: @user.email,
      subject: "Your access to #{@venue.name} has been removed"
    )
  end
end
