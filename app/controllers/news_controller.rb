class NewsController < ApplicationController
  def index
    @news = news_data("fantasy mlb")
  end
  
  def baseball
    @news = news_data("fantasy mlb")
  end
  
  def football
    @news = news_data("fantasy nfl")
  end
  
  def hockey
    @news = news_data("fantasy nhl")
  end
end
