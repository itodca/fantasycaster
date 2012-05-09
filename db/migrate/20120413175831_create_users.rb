class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :name
      t.text :token
      t.text :secret
      t.text :session_handle

      t.timestamps
    end
  end
end
