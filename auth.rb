require './lastfm.rb'
require 'json'
require 'net/http'
require 'dotenv'

# \o/

class Auth < Lastfm

  def get_token
    params = {
      :method => 'auth.gettoken',
      :api_key => @api_key
    }
    data = api_request(params, :get)
    data['token']
  end

  def open_browser(token)
    # this works on mac only!
    system("open", "http://www.last.fm/api/auth/?api_key=#{@api_key}&token=#{token}")
  end

  def get_session
    auth_file = File.read('auth.json')
    auth_data = JSON.parse(auth_file)

    session_key = auth_data['session_key']
    token = auth_data['token']

    if !session_key
      if !token 
        puts "Getting a new token"
        token = get_token
        open_browser(token)
        puts "Please press enter when you are done"
        enter = gets.chomp
      end

      params = { 
        'method' => 'auth.getSession',
        'token' => token,
        'api_key' => @api_key
      }

      puts "Getting a new session"
      session_data = api_request(params, :get)
      err = session_data['error']
      if err
        puts "There is an error! #{err}"
        err = err.to_i
        if err == 14 || err == 15 || err == 4
          @token = nil
          clear
        end
        raise BadSessionException, "ARGGH WHOILE GETSTA AS ESSSIONS"
      end

      auth_file = File.open('auth.json', 'w')

      session_key = session_data['session']['key']
      auth_file << {
        'session_key' => session_key, 
        'token' => token
      }.to_json
      auth_file.close
    end
    @token = token
    @session_key = session_key
    session_key
  end

  def clear()
    auth_file = File.open('auth.json', 'w')
    auth_file << {'session_key' => nil, 'token' => @token }.to_json
    auth_file.close
  end

end



