require 'net/http'
require 'json'
require 'digest'
# do auth

# The "desktop" version of last.fm's weird auth.

# auth.getToken - this gives us an unauthorised token

# Send user the the login page thing, with the token and our api key - this approves the token
# User logs in. The the user tells us they are done.

# auth.getSession with the auth 

# \o/

# send scrobble with the session.



class Auth
  def initialize(api_key, api_secret)
    @api_key = api_key 
    @api_secret = api_secret
  end

  def get_token
    params = {
      :method => 'auth.gettoken',
      :api_key => @api_key
    }
    data = api_request(params)
    data['token']
  end

  def api_request(params)
    sig = sign_params(params)
    params['api_sig'] = sig
    params['format'] = 'json'
    puts   'making request with params:' + params.inspect
    uri = URI('http://ws.audioscrobbler.com/2.0/')
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)

    data = JSON.parse(response.body)
  end

  def md5(something)
    md5 = Digest::MD5.new
    md5 << something
    md5.hexdigest
  end


  def sign_params(params)
    # client signature
    signature = ""
    params.keys.sort.each do |k|
      signature << k.to_s + params[k].to_s
    end
    md5(signature + @api_secret)
  end


  def open_browser(token)
    # this works on mac only!
    system("open", "http://www.last.fm/api/auth/?api_key=#{@api_key}&token=#{token}")
  end

  def get_session
    #do we have a token already? 
    # no
    token = get_token
    open_browser(token)

    puts "Please press enter when you are done"
    enter = gets.chomp

    params = { 
      'method' => 'auth.getSession',
      'token' => token,
      'api_key' => @api_key
    }

    data = api_request(params)
  end
end

api_key = 'cce078cd600da278c9ee4b2250b94529'
api_secret = '88366b6d0e2f513fb1f77117f40b7010'

test = Auth.new(api_key, api_secret)
puts test.get_session

# save token for posterity

#test.open_browser('cce078cd600da278c9ee4b2250b94529', token)