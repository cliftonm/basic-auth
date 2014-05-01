class User < ActiveRecord::Base
  attr_accessible :email, :username, :password, :password_confirmation, :new_password, :new_password_confirmation, :remember_me, :is_admin
  attr_accessor :password, :new_password, :previous_email, :previous_username, :remember_me
  before_save :encrypt_password

  validates_confirmation_of :password

  validates_confirmation_of :new_password, :if => Proc.new {|user|
    !user.new_password.nil? && !user.new_password.empty? }

  validates_presence_of :password, :on => :create

  validates_presence_of :email, :if => Proc.new {|user|
    user.previous_email.nil? || user.email != user.previous_email}

  validates_presence_of :username, :if => Proc.new {|user|
    user.previous_username.nil? || user.username != user.previous_username}

  validates_uniqueness_of :email, :if => Proc.new {|user|
    user.previous_email.nil? || user.email != user.previous_email}

  validates_uniqueness_of :username, :if => Proc.new {|user|
    user.previous_username.nil? || user.username != user.previous_username}

  def initialize(attributes = {})
    super     # must allow the active record to initialize!
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def update(attributes = {})
    super     # must allow the active record to initialize!
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def self.authenticate_by_email(email, password)
    user = find_by_email(email)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

  def self.authenticate_by_username(username, password)
    user = find_by_username(username)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end
end
