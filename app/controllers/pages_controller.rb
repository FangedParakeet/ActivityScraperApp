class PagesController < ApplicationController

  def search
    url = params[:q]
    if url
      @links = find_activities(url) #See ApplicationController
    end
    respond_to do |format|
      format.json {render json: @links }
    end
  end

end