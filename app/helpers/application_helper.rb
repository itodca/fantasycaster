module ApplicationHelper
  def position_type_description(league_code, abbreviation)
    if league_code == 'mlb'
      abbreviation == 'B' ? 'Batter' : 'Pitcher'
    end
  end
  
  def points_badge(points)
    points.to_f <= 3 ? content_tag(:span, number_to_human(points), :class => "badge badge-error") : number_to_human(points)
  end
  
  def head_to_head_badge(value, status, for_opposing_team)
    if (status == "W" && for_opposing_team == false) || (status == "L" && for_opposing_team == true)
      content_tag(:span, number_to_human(value), :class => "winning-stat")
    else
      number_to_human(value)
    end
  end
  
  def score_badge(value, opposing_value)
    value.to_i > opposing_value.to_i ? content_tag(:strong, number_to_human(value)) : number_to_human(value)
  end
  
  def rankings_badge(rank, team_count)
    if rank.to_f <= 3
      content_tag(:span, number_to_human(rank), :class => "badge badge-success")
    elsif rank.to_f >= team_count - 3
      content_tag(:span, number_to_human(rank), :class => "badge badge-error")
    else
      number_to_human(rank)
    end
  end
  
  def player_status_toggle(position_type, label, status, is_checked)
    "<span class='playerStatus'><input type='checkbox' id='#{position_type}#{status}' class='playerStatus' data-table='#{position_type}' #{'checked' if is_checked} /><label for='#{position_type}#{status}'>#{label}</label></span>".html_safe
  end
end
