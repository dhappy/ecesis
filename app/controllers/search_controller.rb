class SearchController < ApplicationController
  protect_from_forgery with: :null_session

  def complete
    @suggestions = Datum
    .where('name ILIKE ?', "%#{params[:partial]}%")
    .distinct
    .limit(50)
    .select(:name).pluck(:name)

    render json: @suggestions
  end
end
