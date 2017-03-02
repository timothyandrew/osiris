require "google/cloud/storage"

class GoogleStorageDir
  def initialize(prefix, thumbnail)
    @prefix = prefix
    @thumbnail = thumbnail
  end

  def css_class
    "dir"
  end

  def thumb_url
    if @thumbnail
      key = ENV['EMBEDLY_KEY']
      "https://i.embed.ly/1/display/resize?key=#{key}&url=#{CGI::escape(@thumbnail)}&width=150&grow=false"
    end
  end

  def render
    name = @prefix.split("/").last
    if thumb_url
      "<img src='#{thumb_url}' />
    <a href=\"/files/#{@prefix}\">#{name}</a>"
    else
      "<a href=\"/files/#{@prefix}\">#{name}</a>"
    end
  end
end

class GoogleStorageFile
  def self.create(file)
    url = file.signed_url(method: "GET", expires: 86400)
    extension = File.extname(URI.parse(url).path).downcase

    if [".jpg", ".png", ".gif"].include?(extension)
      ImageGoogleStorageFile.new(file)
    elsif [".mov", ".avi", ".mp4"].include?(extension)
      VideoGoogleStorageFile.new(file)
    else
      GoogleStorageFile.new(file)
    end
  end

  def initialize(file)
    @file = file
  end

  def css_class
    ""
  end

  def url
    @file.signed_url(method: "GET", expires: 86400) if @file
  end

  def image_url
    key = ENV['EMBEDLY_KEY']
    "https://i.embed.ly/1/display/resize?key=#{key}&url=#{CGI::escape(url)}&width=150&grow=false"
  end

  def render
    ""
  end
end

class ImageGoogleStorageFile < GoogleStorageFile
  def render
    "<a target=\"_blank\" href=\"#{url}\"><img src=#{image_url} /></a>"
  end

  def css_class
    "image"
  end
end

class VideoGoogleStorageFile < GoogleStorageFile
  def render
    "<video width=\"490\" height=\"200\" controls class=\"video-js vjs-default-skin vjs-big-play-centered\" preload=\"metadata\" data-setup=\"{}\">
       <source src=\"#{url}\" type=\"video/mp4\">
     </video>
    "
  end

  def css_class
    "video"
  end
end


class GoogleStorageService
  def initialize
    @storage = Google::Cloud::Storage.new(
      project: ENV["GOOGLE_PROJECT"],
      keyfile: ENV["GOOGLE_KEYFILE"]
    )

    @bucket = @storage.bucket("rakshitha-tim-photos")
  end

  def image?(file)
    extension = File.extname(file.name).downcase
    [".jpg", ".png", ".gif"].include?(extension)
  end

  # Given a prefix, find all it's sub-directories, and cache a thumbnail for each one.
  def write_thumbnails!(prefix)
    sub_dirs = @bucket.files(prefix: prefix, delimiter: '/').prefixes

    if sub_dirs
      sub_dirs.each { |dir| write_thumbnails!(dir) }
    end

    thumbnail_file = GoogleStorageFile.new(@bucket.files(prefix: prefix, delimiter: '/').to_a.find_all { |file| image?(file) }.sample)

    if thumbnail_file
      thumbnail = thumbnail_file.url
      ThumbnailCache.put(prefix, thumbnail, 6.days.from_now)
      thumbnail
    end
  end

  def list(path)
    files = if path.present?
              @bucket.files(prefix: "#{path}/", delimiter: "/")
            else
              @bucket.files(delimiter: "/")
            end

    directories = files.prefixes.map do |prefix|
      thumbnail = ThumbnailCache.get(prefix).image_path
      GoogleStorageDir.new(prefix, thumbnail)
    end

    [] + files.map { |file| GoogleStorageFile.create(file) } + directories.reverse
  end
end
