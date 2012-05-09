class GamesController < ApplicationController
  def index
  end
  
  def show
    if (params[:id] && params[:l] && params[:t])
      @league_data = league_data(params[:id], params[:l])
      @league_code = teams_data.css("league").find{|t| t.at_css("league_id").text == params[:l]}.parent.parent.at_css("code").text
      @league_teams_statistics = league_teams_statistics(@league_data, params[:t])
      @statistic_types = statistic_types(@league_data)
      if @league_data.at_css("scoring_type").text == "head"
        @current_week = @league_data.at_css("current_week").text
        @matchup_scores = matchup_scores(matchups_data(params[:id], params[:l], params[:t]), @league_data, params[:t])
        @upcoming_opponents = upcoming_opponents(matchups_data(params[:id], params[:l], params[:t]), @league_data, params[:t])
      end
    end
  end
  
  def players
    if (params[:id] && params[:l] && params[:t])
      @detailed_rankings = detailed_rankings(params[:id], params[:l], params[:t])
      @league_data = league_data(params[:id], params[:l])
      @league_code = teams_data.css("league").find{|t| t.at_css("league_id").text == params[:l]}.parent.parent.at_css("code").text
      @statistic_types = statistic_types(@league_data)
    end
    
    render :layout => false
  end
end
