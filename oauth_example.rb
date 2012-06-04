$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__)+"/../lib/")
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rubygems"
require 'uri'
require 'cgi'
require 'sinatra'
require 'faraday'
require 'pry'
require 'json'
require 'openssl'
# require 'example_config'

CONFIG = { :auth_url      => ("https://auth.tfoundry.com"),
           :client_id     => ('e6b0570f56904fe81022efd6afa1ec99'), 
           :client_secret => ('c68ae72a5c7aa68d'),
           :endpoint      => ('http://api.tfoundry.com'),
           :redirect_uri  => ('http://localhost:4567/auth/att/callback')
         }

#FIXME, this is not secure
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class ExampleServer < Sinatra::Base
  configure do
    enable :logging
  end

  attr_reader :access_token

  get '/hi' do
    'hi'
  end

  get '/' do
    url = "#{CONFIG[:auth_url]}/oauth/authorize?redirect_uri=#{CGI.escape(CONFIG[:redirect_uri])}&client_id=#{CONFIG[:client_id]}&scope=profile&response_type=code"
    "<a href=\"#{url}\">#{url}</a>"
  end

  get '/auth/att/callback' do
    puts params
    access_token_url = "#{CONFIG[:auth_url]}/oauth/token?redirect_uri=#{CGI.escape(CONFIG[:redirect_uri])}&code=#{params[:code]}&client_id=#{CONFIG[:client_id]}&client_secret=#{CONFIG[:client_secret]}&grant_type=authorization_code"
    result = Faraday.post(access_token_url)
    p [:result, result]
    data = JSON.parse(result.body)
    @access_token = data['access_token']
    <<-EOE
    access_token = #{data['access_token']}
    <a href="#{CONFIG[:auth_url]}/me.json?access_token=#{access_token}">Me!</a>
    EOE
  end

  get '/me' do
    if @access_token
      p [:me, @access_token]
      access_token_url = "#{CONFIG[:auth_url]}/me.json?access_token=#{access_token}"
      result = Faraday.get(access_token_url.to_s)
      JSON.parse(result)
    else
      redirect '/'
    end
  end
  
end


# ExampleServer.run if $0 == __FILE__