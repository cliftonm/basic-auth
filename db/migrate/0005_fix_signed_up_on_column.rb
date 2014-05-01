class FixSignedUpOnColumn < ActiveRecord::Migration
  def self.up
    remove_column :users, :sign_up_on
    add_column :users, :sign_up_on, :datetime
  end

  def self.down
  end
end
