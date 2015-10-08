class CreateThumbnailCaches < ActiveRecord::Migration
  def change
    create_table :thumbnail_caches do |t|
      t.text :directory_path
      t.text :image_path
      t.datetime :expires_at

      t.timestamps null: false
    end
    add_index :thumbnail_caches, [:directory_path, :expires_at], unique: true
  end
end
