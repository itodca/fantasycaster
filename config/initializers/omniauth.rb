module OmniAuth
  module Strategies

    # An omniauth 1.0 strategy for yahoo authentication
    class Yahoo < OmniAuth::Strategies::OAuth
      
      option :name, 'yahoo'
      
      option :client_options, {
        :access_token_path  => '/oauth/v2/get_token',
        :authorize_path     => '/oauth/v2/request_auth',
        :request_token_path => '/oauth/v2/get_request_token',
        :site               => 'https://api.login.yahoo.com'
      }

      uid { 
        access_token.params['xoauth_yahoo_guid']
      }
      
      info do 
        primary_email = nil
        if user_info
          if user_info['emails']
            email_info    = user_info['emails'].find{|e| e['primary']} || user_info['emails'].first
            primary_email = email_info['handle']
          end
          {
            :nickname    => user_info['nickname'],
            :name        => user_info['givenName'] || user_info['nickname'],
            :image       => user_info['image']['imageUrl'],
            :description => user_info['message'],
            :email       => primary_email,
            :urls        => {
              'Profile' => user_info['profileUrl'],
            }
          }
        else
          {}
        end
      end
      
      extra do
        {
          :raw_info => raw_info
        }
      end

      # Return info gathered from the v1/user/:id/profile API call 
     
      def raw_info
        # This is a public API and does not need signing or authentication
        request = "http://social.yahooapis.com/v1/user/#{uid}/profile?format=json"
        @raw_info ||= MultiJson.decode(access_token.get(request).body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end

      # Provide the "Profile" portion of the raw_info
      
      def user_info
        @user_info ||= raw_info.nil? ? {} : raw_info["profile"]
      end
    end
  end
end


Rails.application.config.middleware.use OmniAuth::Builder do  
  provider :yahoo, 'dj0yJmk9b3lhQjBpblRvNUJnJmQ9WVdrOVNGVnhSMWQwTldjbWNHbzlORFExTXpRNE1qWXkmcz1jb25zdW1lcnNlY3JldCZ4PTVi', '2b4c9afe57a04e2e8f99328e097dbc082453265d'  
end  
