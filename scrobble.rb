require './auth.rb'
require './lastfm.rb'
require 'logger'
require 'dotenv'

Dotenv.load

LOG = Logger.new('scrobbler.log')

@api_key = ENV['LASTFM_API_KEY']
@api_secret = ENV['LASTFM_SECRET']

class Scrobbler < Lastfm

  def scrobble(session, attempt = 0)    
    scrobble = {
      artist: 'The Beatles',
      track: 'Hey Jude',
      album: 'Past Masters Volume 2',
      timestamp: Time.now.to_i,
      method: 'track.scrobble',
      api_key: @api_key,
      sk: session
    }
    data = api_request(scrobble, :post)
    
    err = data['error']
    if err
      # log things here
      err = data['error'].to_i
      message = data['message']
      logHash = {
        http_code: @response.code,
        http_body: @response.body,
        http_headers: @response.to_hash,
        lfm_error: err,
        lfm_message: message
      }

      if err == 16 || err == 11 
        raise ServerErrorException, "#{logHash}"
      elsif err == 9 # Bad session -- user needs to reauthenticate
        raise BadSessionException, "#{logHash}"
      else
        raise "there is no exception class big enough to hold this error"
      end
    else
      puts "We scrobbled " + scrobble.inspect
      puts "HURRAY YOU ARE THE BEST AT THIS"
    end
  end
end



def run(attempt = 1)
  if attempt >= 5
    puts "ARGH too many retries" 
    exit 1
  end

  begin
    auth = Auth.new(@api_key, @api_secret)
    session = auth.get_session
    
    scrobbler = Scrobbler.new(@api_key, @api_secret)
    scrobbler.scrobble(session)
  rescue ServerErrorException => e
    LOG.error(e) # logs to file
    puts e.message # print to stdout
    puts 'retrying in ' + (2 ** attempt).to_s + ' seconds'
    sleep(2 ** attempt)
    run(attempt + 1)
  rescue BadSessionException => e
    LOG.error(e) # logs to file
    puts e.message # print to stdout
    auth.clear()
    puts 'retrying'
    run(attempt + 1)
  rescue => e
    LOG.error(e) # logs to file
    raise
  end
end

run

