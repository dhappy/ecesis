class SearchController < ApplicationController
  protect_from_forgery with: :null_session

  def complete
    @suggestions = Datum
    .where('name ILIKE ?', "%#{params[:partial]}%")
    .limit(15)
    .select(:name).pluck(:name)

    render json: @suggestions
  end
end
