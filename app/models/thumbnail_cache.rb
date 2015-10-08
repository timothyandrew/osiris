class ThumbnailCache < ActiveRecord::Base
  def self.get(directory_path)
    ThumbnailCache.where("expires_at > ?", Time.now).where(directory_path: directory_path).order(created_at: :desc).first_or_initialize
  end

  def self.put(directory_path, image_path, expires_at)
    ThumbnailCache.create!(directory_path: directory_path, image_path: image_path, expires_at: expires_at)
  end
end
