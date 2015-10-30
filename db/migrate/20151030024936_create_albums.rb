class CreateAlbums < ActiveRecord::Migration
  def change
    create_table :albums do |t|
      t.text :s3_key
      t.text :share_key

      t.timestamps null: false
    end
  end
end
