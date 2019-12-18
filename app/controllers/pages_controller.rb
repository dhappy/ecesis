class PagesController < ApplicationController
  protect_from_forgery with: :null_session

  def import
    @title = 'Awards: Import Data'
  end

  def stats
    @title = 'Awards: Statistics'
  end

  def home; end

  def upload
    byebug
  end
end