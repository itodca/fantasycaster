module YahooQueryHelper
  # Exchange your oauth_token and oauth_token_secret for an AccessToken instance.
  def prepare_access_token(oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new("dj0yJmk9b3lhQjBpblRvNUJnJmQ9WVdrOVNGVnhSMWQwTldjbWNHbzlORFExTXpRNE1qWXkmcz1jb25zdW1lcnNlY3JldCZ4PTVi", "2b4c9afe57a04e2e8f99328e097dbc082453265d",
      { :site => "https://api.login.yahoo.com",
        :request_token_path => "/oauth/v2/get_request_token",
        :access_token_path => "/oauth/v2/get_token",
        :authorize_path => "/oauth/v2/request_auth"
      })
    # now create the access token object from passed stats
    token_hash = { :oauth_token => oauth_token,
                   :oauth_token_secret => oauth_token_secret
                 }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash)
    return access_token
  end
  
  def refresh_access_token(oauth_token, oauth_token_secret, oauth_session_handle)
    consumer = OAuth::Consumer.new("dj0yJmk9b3lhQjBpblRvNUJnJmQ9WVdrOVNGVnhSMWQwTldjbWNHbzlORFExTXpRNE1qWXkmcz1jb25zdW1lcnNlY3JldCZ4PTVi", "2b4c9afe57a04e2e8f99328e097dbc082453265d",
      { :site => "https://api.login.yahoo.com",
        :request_token_path => "/oauth/v2/get_request_token",
        :access_token_path => "/oauth/v2/get_token",
        :authorize_path => "/oauth/v2/request_auth"
      })
    
    token_hash = { :oauth_token => oauth_token,
                   :oauth_token_secret => oauth_token_secret
                 }
                   
    request_token = OAuth::RequestToken.new(consumer, oauth_token, oauth_token_secret)
    token = OAuth::Token.new(oauth_token, oauth_token_secret)
    access_token = request_token.get_access_token(
                               :oauth_session_handle => oauth_session_handle,
                               :token => token)
    current_user.token = access_token.token
    current_user.secret = access_token.secret
    current_user.save!
    return access_token
  end
  
  def request_data(query)
    if current_user.present?
      # Exchange our oauth_token and oauth_token secret for the AccessToken instance.
      access_token = prepare_access_token(current_user.token, current_user.secret) 
      # use the access token as an agent to get the home timeline
      begin
        access_token.request(:get, "#{query}").body
      rescue
        access_token = refresh_access_token(current_user.token, current_user.secret, current_user.session_handle)
        access_token.request(:get, "#{query}").body
      end
    end
  end
  
  def get_yahoo_document(directory, filename, uri)
    FileUtils.mkdir_p(directory) unless File.directory?(directory)
    
    filename = "#{directory}#{filename}.xml"
    doc = nil
    if File.exists?(filename) && File.size(filename) > 0
      file = File.open(filename)
      doc = Nokogiri::XML(file)
      file.close
    else
      data = request_data(uri)
      File.open(filename, 'wb') { |f| f.write(data) }
      doc = Nokogiri::XML(data)
    end
    return doc
  end
  
  def generate_league_key(game_id, league_id)
    "#{game_id}.l.#{league_id}"
  end
  
  def generate_team_key(game_id, league_id, team_id)
    "#{generate_league_key(game_id, league_id)}.t.#{team_id}"
  end
  
  def stats_date
    Time.now.advance(:hours => -8).to_date
  end
  
  def league_path(game_id, league_id)
    "xml/#{stats_date}/games/#{game_id}/leagues/#{league_id}/"
  end
  
  def teams_data
    get_yahoo_document("xml/#{stats_date}/users/", current_user.id, "http://fantasysports.yahooapis.com/fantasy/v2/users;use_login=1/games/leagues/teams")
  end
  
  def league_data(game_id, league_id)
    get_yahoo_document(league_path(game_id, league_id), "league", "http://fantasysports.yahooapis.com/fantasy/v2/league/#{generate_league_key(game_id, league_id)};out=settings,standings,scoreboard")
  end
  
  def roster_data(game_id, league_id, team_id)
    get_yahoo_document("#{league_path(game_id, league_id)}rosters/", team_id, "http://fantasysports.yahooapis.com/fantasy/v2/team/#{generate_team_key(game_id, league_id, team_id)}/players/stats;type=lastmonth")
  end
  
  def matchups_data(game_id, league_id, team_id)
    get_yahoo_document("#{league_path(game_id, league_id)}matchups/", team_id, "http://fantasysports.yahooapis.com/fantasy/v2/team/#{generate_team_key(game_id, league_id, team_id)}/matchups")
  end
  
  def season_player_statistics_data(game_id, league_id, stat_id, options = {})
    get_yahoo_document("#{league_path(game_id, league_id)}stats/season/", stat_id.to_s, "http://fantasysports.yahooapis.com/fantasy/v2/league/#{generate_league_key(game_id, league_id)}/players;sort=#{stat_id};#{options[:positions] ? "position=" + options[:positions] + ";" : ""}#{options[:status] ? "status=" + options[:status] + ";" : ""}count=25;sort_type=season;out=stats,ownership")
  end
  
  def lastmonth_player_statistics_data(game_id, league_id, stat_id, options = {})
    get_yahoo_document("#{league_path(game_id, league_id)}stats/lastmonth/", stat_id.to_s, "http://fantasysports.yahooapis.com/fantasy/v2/league/#{generate_league_key(game_id, league_id)}/players;sort=#{stat_id};#{options[:positions] ? "position=" + options[:positions] + ";" : ""}#{options[:status] ? "status=" + options[:status] + ";" : ""}count=25;sort_type=lastmonth;out=ownership/stats;type=lastmonth")
  end
  
  def statistic_types(league_data)
    Hash[league_data.css("stat_categories stat").map{|s| [s.at_css("stat_id").text, {:name => s.at_css("name").text, :display_name => s.at_css("display_name").text, :sort_order => s.at_css("sort_order").text, :position_type => s.at_css("position_type").text, :is_only_display_stat => s.at_css("is_only_display_stat") }]}]
  end
  
  def statistic_names(league_data)
    Hash[league_data.css("stat_categories stat").map{|s| [s.at_css("stat_id").text, s.at_css("display_name").text]}]
  end
  
  def positions(league_data, position_type)
    league_data.css("roster_position").find_all{|p| p.at_css("position_type").present? && p.at_css("position_type").text == position_type}.map{|p| p.at_css("position").text}.join(",")
  end
  
  def league_teams_statistics(league_data, team_id)
    teams = {}
    stat_types = statistic_types(league_data)
    league_data.css("standings team").each do |team|
      team_hash = {:team_name => team.at_css("name").text, :logo_url => team.at_css("team_logo url").text, :rank => team.at_css("team_standings rank").text, :url => team.at_css("url").text, :total_points => team.at_css("team_points total").text, :stats => {}}
      team.css("stat").each do |stat|
        stat_type = stat_types[stat.at_css("stat_id").text]
        team_hash[:stats][stat.at_css("stat_id").text] = {:name => stat_type[:name], :display_name => stat_type[:display_name], :sort_order => stat_type[:sort_order], :value => stat.at_css("value").text} if stat_type[:is_only_display_stat].nil?
      end
      teams[team.at_css("team_id").text] = team_hash
    end
    user_team = teams[team_id]
    teams.each do |team_key, team|
      team[:stats].each do |stat_key, stat|
        stat[:user_stat_value] = user_team[:stats][stat_key][:value]
        stat[:status] = head_to_head_status(stat[:user_stat_value].to_f, stat[:value].to_f, stat[:sort_order])
      end
    end
    return teams
  end
  
  def matchup_scores(matchups_data, league_data, team_id)
    matchups = {}
    stat_types = statistic_types(league_data)
    matchups_data.css("matchups matchup").find_all{|m| m.at_css("status").text != "preevent"}.each do |matchup|
      user_team = matchup.css("team").find{|t| t.at_css("team_id").text == team_id}
      opposing_team = matchup.css("team").find{|t| t.at_css("team_id").text != team_id}
      matchup_hash = {:team_name => user_team.at_css("name").text, :opp_team_name => opposing_team.at_css("name").text, :logo_url => opposing_team.at_css("team_logo url").text, :url => matchup.at_css("url").text, :points => user_team.at_css("team_points total").text, :opp_points => opposing_team.at_css("team_points total").text, :stats => {}}
      user_team.css("stat").each do |stat|
        matchup_hash[:stats][stat.at_css("stat_id").text] = {:value => stat.at_css("value").text} if stat_types[stat.at_css("stat_id").text][:is_only_display_stat].nil?
      end
      opposing_team.css("stat").each do |stat|
        if stat_types[stat.at_css("stat_id").text][:is_only_display_stat].nil?
          matchup_hash[:stats][stat.at_css("stat_id").text][:opp_value] = stat.at_css("value").text
          matchup_hash[:stats][stat.at_css("stat_id").text][:status] = head_to_head_status(matchup_hash[:stats][stat.at_css("stat_id").text][:value].to_f, matchup_hash[:stats][stat.at_css("stat_id").text][:opp_value].to_f, stat_types[stat.at_css("stat_id").text][:sort_order])
        end
      end
      matchups[matchup.at_css("week").text] = matchup_hash
    end
    return matchups
  end
  
  def head_to_head_status(user_stat, opp_stat, sort_order)
    status = "W"
    if user_stat == opp_stat
      status = "T"
    elsif (sort_order == "1" && user_stat < opp_stat) || (sort_order == "0" && user_stat > opp_stat)
      status = "L"
    end
    return status
  end
  
  def upcoming_opponents(matchups_data, league_data, team_id)
    league_teams_stats = league_teams_statistics(league_data, team_id)
    opponents = {}
    current_week = league_data.at_css("current_week").text
    matchups_data.css("matchups matchup").find_all{|m| m.at_css("status").text == "preevent" && m.at_css("week").text.to_i < current_week.to_i + 3}.each do |matchup|
      opposing_team = matchup.css("team").find{|t| t.at_css("is_current_login").nil?}
      team_id = opposing_team.at_css("team_id").text
      opponents[team_id] = {:week => matchup.at_css("week").text, :opp_team_name => opposing_team.at_css("name").text, :logo_url => opposing_team.at_css("team_logo url").text, :url => matchup.at_css("url").text, :stats => league_teams_stats[team_id][:stats]}
    end
    return opponents
  end
  
  def league_points(league_data)
    teams = {}
    league_data.css("standings team").each do |team|
      teams[team.at_css("team_id").text] ={:team_name => team.at_css("name").text, :rank => team.at_css("team_standings rank").text, :total_points => team.at_css("team_points total").text, :stats => {}}
    end
    stat_types = statistic_types(league_data)
    league_data.css("standings stat").group_by{|s| s.at_css("stat_id").text}.each do |stat_id, team_stats|
      stat = stat_types[stat_id]
      if stat[:is_only_display_stat].nil?
        if stat[:sort_order] == "1"
          team_stats = team_stats.sort_by{|v| v.at_css("value").text.to_f}
        else
          team_stats = team_stats.sort_by{|v| v.at_css("value").text.to_f}.reverse
        end
        
        duplicate_count = 1
        points = 1
        stat_rankings = {}
        team_stats.each_with_index do |team_stat, index|
          if duplicate_count == 1
            points = index + 1
            i = 1
            while team_stats[index + i].present? && team_stats[index + i].at_css("value").text.to_f == team_stat.at_css("value").text.to_f
              points += index + 1 + i
              duplicate_count += 1
              i += 1
            end
            points = points.to_f / duplicate_count
          else
            duplicate_count -= 1
          end
          stat_rankings[team_stat.parent.parent.parent.at_css("team_id").text] = points
        end
        teams.each do |k, v|
          v[:stats][stat_id] = {:name => stat[:name], :display_name => stat[:display_name], :sort_order => stat[:sort_order], :position_type => stat[:position_type], :points => stat_rankings[k]}
        end
        
      end
    end
    return Hash[teams.sort_by{|k,v| v[:rank].to_i}]
  end
  
  def league_rankings(league_data)
    teams = {}
    league_data.css("standings team").each do |team|
      teams[team.at_css("team_id").text] ={:team_name => team.at_css("name").text, :rank => team.at_css("team_standings rank").text, :total_points => team.at_css("team_points total").text, :stats => {}}
    end
    stat_types = statistic_types(league_data)
    league_data.css("standings stat").group_by{|s| s.at_css("stat_id").text}.each do |stat_id, team_stats|
      stat = stat_types[stat_id]
      if stat[:is_only_display_stat].nil?
        if stat[:sort_order] == "1"
          team_stats = team_stats.sort_by{|v| v.at_css("value").text.to_f}.reverse
        else
          team_stats = team_stats.sort_by{|v| v.at_css("value").text.to_f}
        end
        
        stat_rankings = {}
        team_stats.each_with_index do |team_stat, index|
          if index == 0
            stat_rankings[stat.parent.parent.parent.at_css("team_id").text] = 1
          else
            stat_rankings[stat.parent.parent.parent.at_css("team_id").text] = team_stats[index - 1].at_css("value").text.to_f == team_stat.at_css("value").text.to_f ? stat_rankings[team_stats[index - 1].parent.parent.parent.at_css("team_id").text] : index + 1
          end
        end
        teams.each do |k, v|
          v[:stats][stat_id] = {:name => stat[:name], :display_name => stat[:display_name], :sort_order => stat[:sort_order], :position_type => stat[:position_type], :rank => stat_rankings[k]}
        end
        
      end
    end
    return Hash[teams.sort_by{|k,v| v[:rank].to_i}]
  end
  
  def roster_rankings(rosters_data, stat_types)
    players = {}
    rosters_data.css("player").each do |player|
      players[player.at_css("player_id").text] ={:player_name => player.at_css("name full").text, :positions => player.css("eligible_positions").css("position").map{|p| p.text}.join(", "), :image_url => player.at_css("image_url").text, :position_type => player.at_css("position_type").text, :stats => {}}
    end
    rosters_data.css("player_stats stat").group_by{|s| s.at_css("stat_id").text}.each do |stat_id, player_stats|
      stat = stat_types[stat_id]
      if stat[:sort_order] == "1"
        player_stats = player_stats.sort_by{|v| v.at_css("value").text.to_f}.reverse
      else
        player_stats = player_stats.sort_by{|v| v.at_css("value").text.to_f}
      end
      
      stat_rankings = {}
      player_stats.each_with_index do |player_stat, index|
        rank = 0
        if stat[:is_only_display_stat].nil?
          if index == 0
            rank = 1
          else
            rank = player_stats[index - 1].at_css("value").text.to_f == player_stat.at_css("value").text.to_f ? stat_rankings[player_stats[index - 1].parent.parent.parent.at_css("player_id").text][:rank] : index + 1
          end
        end
        stat_rankings[player_stat.parent.parent.parent.at_css("player_id").text] = {:rank => rank, :value => player_stat.at_css("value").text}
      end
      players.find_all{|k, v| v[:position_type] == stat[:position_type]}.each do |k, v|
        v[:stats][stat_id] = {:name => stat[:name], :display_name => stat[:display_name], :rank => stat_rankings[k][:rank], :value => stat_rankings[k][:value]}
      end
    end
    players.each do |k, v|
      v[:total_rank] = v[:stats].map{|k, v| v[:rank]}.sum
    end
    return Hash[players.sort_by{|k, v| v[:total_rank]}]
  end
  
  def detailed_rankings(game_id, league_id, team_id)
    roster_xml = roster_data(game_id, league_id, team_id)
    xml_array = [roster_xml]
    league_xml = league_data(game_id, league_id)
    team_name = league_xml.css("team").find{|t| t.at_css("team_id").text == team_id}.at_css("name").text
    
    players = {}
    roster_xml.css("player").each do |player|
      if players[player.at_css("player_id").text].nil?
        players[player.at_css("player_id").text] = {:player_name => player.at_css("name full").text, :positions => player.css("eligible_positions").css("position").map{|p| p.text}.join(", "), :image_url => player.at_css("image_url").text, :position_type => player.at_css("position_type").text, :status => "U", :owner => team_name, :stats => {}}
      end
    end
  
    stat_types = statistic_types(league_xml)
    stat_types.each do |k,v|
      xml_array.push(lastmonth_player_statistics_data(game_id, league_id, k, :positions => positions(league_xml, v[:position_type])))
    end
    
    builder = Nokogiri::XML::Builder.new do |xml_out|
      xml_out.players {
        xml_array.each do |xml|
          xml_out << xml.css("player").to_xml.to_str
        end
      }
    end
    
    players_data = Nokogiri::XML(builder.to_xml)
    seen = Hash.new(0)
    players_data.css("player").each do |player|
      player_id = player.at_css("player_id").text
      players[player_id] = {:player_name => player.at_css("name full").text, :positions => player.css("eligible_positions").css("position").map{|p| p.text}.join(", "), :image_url => player.at_css("image_url").text, :position_type => player.at_css("position_type").text, :owner => player.at_css("owner_team_name").nil? ? "Available" : player.at_css("owner_team_name").text, :status => player.at_css("owner_team_name").nil? ? "A" : "O", :stats => {}} if players[player_id].nil?
      player.unlink if (seen[player_id] += 1) > 1
    end

    players_data.css("player_stats stat").group_by{|s| s.at_css("stat_id").text}.each do |stat_id, player_stats|
      player_stats_hash = Hash[player_stats.map{|s| [s.parent.parent.parent.at_css("player_id").text, s.at_css("value").text]}]
      
      stat = stat_types[stat_id]
      if stat[:sort_order] == "1"
        player_stats_hash = Hash[player_stats_hash.sort_by{|k, v| v.to_f}.reverse]
      else
        player_stats_hash = Hash[player_stats_hash.sort_by{|k, v| v.to_f}]
      end
      stat_rankings = {}
      player_stats_hash.each_with_index do |(k, v), index|
        rank = 0
        if stat[:is_only_display_stat].nil?
          if index == 0
            rank = 1
          else
            rank = player_stats_hash[@previous_key].to_f == v.to_f ? stat_rankings[@previous_key][:rank] : index + 1
          end
        end
        @previous_key = k
        stat_rankings[k] = {:rank => rank, :value => v}
      end
      players.find_all{|k, v| v[:position_type] == stat[:position_type]}.each do |k, v|
        if stat_rankings[k].present?
          v[:stats][stat_id] = {:name => stat[:name], :display_name => stat[:display_name], :rank => stat_rankings[k][:rank], :value => stat_rankings[k][:value]}
        end
      end
    end
    
    players.each do |k, v|
      v[:total_rank] = v[:stats].map{|k, v| v[:rank]}.sum
    end
    return Hash[players.sort_by{|k, v| v[:total_rank]}]
  end
end
