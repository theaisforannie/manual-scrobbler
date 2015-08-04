require 'uri'
require 'json'
require 'digest'

class ServerErrorException < Exception
end


class BadSessionException < Exception
end

class Lastfm
  def initialize(api_key, api_secret)
    @api_key = api_key 
    @api_secret = api_secret
  end

  def api_request(params, method)
    sig = sign_params(params)
    params['api_sig'] = sig
    params['format'] = 'json'
    # puts   'making request with params:' + params.inspect
    uri = URI('http://ws.audioscrobbler.com/2.0/')

    if method == :get 
      uri.query = URI.encode_www_form(params)
      @response = Net::HTTP.get_response(uri)
    elsif method == :post
      @response = Net::HTTP.post_form(uri, params)
    else
      raise ":("
    end

    data = JSON.parse(@response.body)
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
end