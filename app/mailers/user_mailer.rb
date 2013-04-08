class UserMailer < ActionMailer::Base
  default from: 'marc.clifton@outlook.com'

  def welcome_email(user)
    @user = user
    @url = 'http://localhost:3000/sign_in'
    @site_name = "localhost"
    mail(:to => user.email, :subject => 'Welcome to my website.')
  end

  def reset_password_email(user)
    @user = user
    @password_reset_url = 'http://localhost:3000/password_reset?' + @user.password_reset_token
    mail(:to => user.email, :subject => 'Password Reset Instructions.')
  end
end
