class FilesController < ApplicationController
  before_filter :assign_album, only: :index
  skip_before_filter :authenticate_user!, only: :index
  before_filter :authenticate_user_if_share_key_present

  def index
    @path = params[:path].presence
    @files = Kaminari.paginate_array(S3Service.new.list(@path)).page(params[:page]).per(params[:per_page].presence || 100)
  end

  private

  def assign_album
    @album = Album.find_or_create_by_path(params[:path])
  end

  def authenticate_user_if_share_key_present
    if user_signed_in? || @album.share_key == params[:share_key]
      # Do nothing
    else
      redirect_to new_user_session_path, alert: "Sorry, you can't view this page"
    end
  end
end
