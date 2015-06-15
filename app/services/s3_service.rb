class S3Dir
  def initialize(prefix)
    @prefix = prefix
  end

  def render
    name = @prefix.split("/").last
    "<a href='/files/#{@prefix}'>#{name}</a>"
  end
end

class S3File
  def initialize(file)
    @file = file
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
    files = directory.files.map do |file_or_dir|
      S3File.new(file_or_dir)
    end
    dirs = directory.files.common_prefixes.map { |prefix| S3Dir.new(prefix) }
    [] + files + dirs
  end
end
