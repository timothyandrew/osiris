class S3Dir
  def initialize(prefix)
    @prefix = prefix
  end

  def css_class
    "dir"
  end

  def render
    name = @prefix.split("/").last
    "<a href=\"/files/#{@prefix}\">#{name}</a>"
  end
end

class S3File
  def self.create(file)
    url = file.url(Time.now.to_i + 86400)
    extension = File.extname(URI.parse(url).path)
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
    @file.url(Time.now.to_i + 86400)
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

  def dir?(maybe_dir)
    maybe_dir.is_a?(Fog::Storage::AWS::Files)
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
    dirs = directory.files.common_prefixes.map { |prefix| S3Dir.new(prefix) }
    [] + files + dirs.reverse
  end
end
