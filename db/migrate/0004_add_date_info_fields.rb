class AddDateInfoFields < ActiveRecord::Migration
  def self.up
    add_column :users, :sign_up_on, :datetime
    add_column :users, :last_signed_in_on, :datetime
  end

  def self.down
    remove_column :users, :signed_up_on
    remove_column :users, :last_signed_in_on
  end
end
