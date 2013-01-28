class PagesController < ApplicationController

  def search
    url = params[:q]
    @links = find_activities(url) #See ApplicationController
    respond_to do |format|
      format.json {render json: @links }
    end
  end

end