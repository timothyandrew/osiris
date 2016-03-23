class S3Dir
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
    else
      "https://placeholdit.imgix.net/~text?txtsize=14&txt=150%C3%97150&w=150&h=150"
    end
  end

  def render
    name = @prefix.split("/").last
    "<img src='#{thumb_url}' />
    <a href=\"/files/#{@prefix}\">#{name}</a>"
  end
end

class S3File
  def self.create(file)
    url = file.url(Time.now.to_i + 86400)
    extension = File.extname(URI.parse(url).path).downcase
    if [".jpg", ".png", ".gif"].include?(extension)
      ImageS3File.new(file)
    elsif [".mov", ".avi", ".mp4"].include?(extension)
      VideoS3File.new(file)
    else
      S3File.new(file)
    end
  end

  def initialize(file)
    @file = file
  end

  def css_class
    ""
  end

  def url
    @file.url(Time.now.to_i + 86400) if @file # 1 week
  end

  def image_url
    key = ENV['EMBEDLY_KEY']
    "https://i.embed.ly/1/display/resize?key=#{key}&url=#{CGI::escape(url)}&width=150&grow=false"
  end

  def render
    "<a target='_blank' href='#{url}'><img src=#{image_url} /></a>"
  end
end

class ImageS3File < S3File
  def render
    "<a target='_blank' href='#{url}'><img src=#{image_url} /></a>"
  end

  def css_class
    "image"
  end
end

class VideoS3File < S3File
  def render
    "<video width='490' height='200' controls class='video-js vjs-default-skin vjs-big-play-centered' preload='metadata' data-setup='{}'>
       <source src='#{url}' type='video/mp4'>
     </video>
    "
  end

  def css_class
    "video"
  end
end


class S3Service
  def initialize
    @connection = Fog::Storage.new({provider: 'AWS', aws_access_key_id: ENV["AWS_ACCESS_KEY"], aws_secret_access_key: ENV["AWS_SECRET_KEY"]})
  end

  def image?(file)
    extension = File.extname(file.key).downcase
    [".jpg", ".png", ".gif"].include?(extension)
  end

  # Given a prefix, find all it's sub-directories, and cache a thumbnail for each one.
  def write_thumbnails!(prefix)
    sub_dirs = @connection.directories.get('tim-mbp-backup', prefix: prefix, delimiter: '/').files.common_prefixes
    sub_dirs.each { |dir| write_thumbnails!(dir) }

    thumbnail_file = S3File.new(@connection.directories.get('tim-mbp-backup', prefix: prefix, delimiter: '/').files.to_a.find_all { |file| image?(file) }.sample)
    if thumbnail_file
      thumbnail = thumbnail_file.url
      ThumbnailCache.put(prefix, thumbnail, 6.days.from_now)
      thumbnail
    end
  end

  def list(path)
    if path.present?
      directory = @connection.directories.get('tim-mbp-backup', prefix: "#{path}/", delimiter: '/')
    else
      directory = @connection.directories.get('tim-mbp-backup', delimiter: '/')
    end
    files = directory.files.map do |file|
      S3File.create(file)
    end
    dirs = directory.files.common_prefixes.map do |prefix|
      thumbnail = ThumbnailCache.get(prefix).image_path
      S3Dir.new(prefix, thumbnail)
    end
    [] + files + dirs.reverse
  end
end
