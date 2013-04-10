class AuthenticationController < ApplicationController
  before_filter :authenticate_user, :only => [:account_settings, :set_account_info]

  def sign_in
    @user = User.new
  end

  # ========= Signing In ==========

  def login
    username_or_email = params[:user][:username]
    user = verify_user(username_or_email)

    if user
      update_authentication_token(user, params[:user][:remember_me])
      user.last_signed_in_on=DateTime.now
      user.save
      session[:user_id] = user.id
      flash[:notice] = 'Welcome.'
      redirect_to :root
    else
      flash.now[:error] = 'Unknown user.  Please check your username and password.'
      render :action => "sign_in"
    end
  end

  # ========= Signing Out ==========

  def signed_out
    # clear the authentication toke when the user manually signs out
    user = User.find_by_id(session[:user_id])

    if user
      update_authentication_token(user, nil)
      user.save
      session[:user_id] = nil
      flash[:notice] = "You have been signed out."
    else
      redirect_to :sign_in
    end
  end

  # ========= Handles Registering a New User ==========

  def new_user
    @user = User.new
  end

  def register
    @user = User.new(params[:user])

    # Don't use !verify_recaptcha, as this terminates the connection with the server.
    # It almost seems as if the verify_recaptcha is being called twice with we use "not".
    if verify_recaptcha
      if @user.valid?
        update_authentication_token(@user, nil)
        @user.signed_up_on = DateTime.now
        @user.last_signed_in_on = @user.signed_up_on
        @user.save
        # UserMailer.welcome_email(@user).deliver
        session[:user_id] = @user.id
        flash[:notice] = 'Welcome.'
        redirect_to :root
      else
        render :action => "new_user"
      end
    else
      flash.delete(:recaptcha_error)  # get rid of the recaptcha error being flashed by the gem.
      flash.now[:error] = 'reCAPTCHA is incorrect.  Please try again.'
      render :action => "new_user"
    end
  end

  # ========= Handles Changing Account Settings ==========

  def account_settings
    @user = current_user
  end

  def set_account_info
    old_user = current_user

    # verify the current password by creating a new user record.
    @user = User.authenticate_by_username(old_user.username, params[:user][:password])

    # verify
    if @user.nil?
      @user = old_user
      @user.errors[:password] = "Password is incorrect."
      render :action => "account_settings"
    else
      # update the user with any new username and email
      @user.update(params[:user])
      # Set the old email and username, which is validated only if it has changed.
      @user.previous_email = old_user.email
      @user.previous_username = old_user.username

      if @user.valid?
        # If there is a new_password value, then we need to update the password.
        @user.password = @user.new_password unless @user.new_password.nil? || @user.new_password.empty?
        @user.save
        flash[:notice] = 'Account settings have been changed.'
        redirect_to :root
      else
        render :action => "account_settings"
      end
    end
  end

  # ========= Handles Password Reset ==========

  # HTTP get
  def forgot_password
    @user = User.new
  end

  # HTTP put
  def send_password_reset_instructions
    username_or_email = params[:user][:username]

    if username_or_email.rindex('@')
      user = User.find_by_email(username_or_email)
    else
      user = User.find_by_username(username_or_email)
    end

    if user
      user.password_reset_token = SecureRandom.urlsafe_base64
      user.password_expires_after = 24.hours.from_now
      user.save
      UserMailer.reset_password_email(user).deliver
      flash[:notice] = 'Password instructions have been mailed to you.  Please check your inbox.'
      redirect_to :sign_in
    else
      @user = User.new
      # put the previous value back.
      @user.username = params[:user][:username]
      @user.errors[:username] = 'is not a registered user.'
      render :action => "forgot_password"
    end
  end

  # The user has landed on the password reset page, they need to enter a new password.
  # HTTP get
  def password_reset
    token = params.first[0]
    @user = User.find_by_password_reset_token(token)

    if @user.nil?
      flash[:error] = 'You have not requested a password reset.'
      redirect_to :root
      return
    end

    if @user.password_expires_after < DateTime.now
      clear_password_reset(@user)
      @user.save
      flash[:error] = 'Password reset has expired.  Please request a new password reset.'
      redirect_to :forgot_password
    end
  end

  # The user has entered a new password.  Need to verify and save.
  # HTTP put
  def new_password
    username = params[:user][:username]
    @user = User.find_by_username(username)

    if verify_new_password(params[:user])
      @user.update(params[:user])
      @user.password = @user.new_password

      if @user.valid?
        clear_password_reset(@user)
        @user.save
        flash[:notice] = 'Your password has been reset.  Please sign in with your new password.'
        redirect_to :sign_in
      else
        render :action => "password_reset"
      end
    else
      @user.errors[:new_password] = 'Cannot be blank and must match the password verification.'
      render :action => "password_reset"
    end
  end

  # ========= Private Functions ==========

  private

  def clear_password_reset(user)
    user.password_expires_after = nil
    user.password_reset_token = nil
  end

  def verify_new_password(passwords)
    result = true

    if passwords[:new_password].blank? || (passwords[:new_password] != passwords[:new_password_confirmation])
      result=false
    end

    result
  end

  # Verifies the user by checking their email and password or their username and password
  def verify_user(username_or_email)
    password = params[:user][:password]
    if username_or_email.rindex('@')
      email=username_or_email
      user = User.authenticate_by_email(email, password)
    else
      username=username_or_email
      user = User.authenticate_by_username(username, password)
    end

    user
  end

  def update_authentication_token(user, remember_me)
    if remember_me == 1
      # create an authentication token if the user has clicked on remember me
      auth_token = SecureRandom.urlsafe_base64
      user.authentication_token = auth_token
      cookies.permanent[:auth_token] = auth_token
    else              # nil or 0
      # if not, clear the token, as the user doesn't want to be remembered.
      user.authentication_token = nil
      cookies.permanent[:auth_token] = nil
    end
  end
end
