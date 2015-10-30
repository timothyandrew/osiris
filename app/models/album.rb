class Album < ActiveRecord::Base
  def self.find_or_create_by_path(path)
    album = Album.find_by_s3_key(path)
    album = Album.create(s3_key: path, share_key: SecureRandom.base64(50)) unless album
    album
  end
end
