class FilesController < ApplicationController
  def index
    @path = params[:path].presence
    @files = S3Service.new.list(@path)
  end
end
