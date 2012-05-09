class User < ActiveRecord::Base
  attr_accessible :name, :provider, :secret, :token, :uid, :session_handle
  
  def self.create_with_omniauth(auth)  
    @user = User.find_or_initialize_by_provider_and_uid(auth["provider"], auth["uid"])
    @user.token = auth["credentials"]["token"]
    @user.secret = auth["credentials"]["secret"]
    @user.session_handle = auth["extra"]["access_token"].params[:oauth_session_handle]
    @user.name = auth["info"]["name"]
    @user.save!
    
    return @user  
  end
end
