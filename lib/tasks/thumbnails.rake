namespace :thumbnails do
  desc "Update all the entries in ThumbnailCache"
  task update: :environment do
    S3Service.new.write_thumbnails!("Photo Library/")
  end
end
