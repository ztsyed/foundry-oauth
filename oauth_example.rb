$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__)+"/../lib/")
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rubygems"
require 'uri'
require 'sinatra'
require 'faraday'
require 'pry'
require 'json'
require 'openssl'
# require 'example_config'

$auth_url = "https://auth.tfoundry.com"
CONFIG = { :auth_url      => "https://auth.tfoundry.com",
           :client_id     => (ENV['ATT_CLIENT_ID']      || 'e6b0570f56904fe81022efd6afa1ec99'), 
           :client_secret => (ENV['ATT_CLIENT_SECRET']  || 'c68ae72a5c7aa68d'),
           :endpoint      => (ENV['ATT_API_ENDPOINT']   || 'http://api.tfoundry.com'),
           :redirect_uri  => (ENV['ATT_REDIRECT_URI']   || 'http://localhost:4567/auth/att/callback')
         }

TEST_MISDN = (ENV['ATT_TEST_MISDN'] || '6505551212')

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
    url = "#{CONFIG[:auth_url]}/oauth/authorize?client_id=#{CONFIG[:client_id]}&scope=profile&response_type=authorization_code&redirect_uri=#{URI.escape(CONFIG[:redirect_uri])}"
    "<a href=\"#{url}\">#{url}</a>"
  end

  get '/auth/att/callback' do
    puts params
    access_token_url = "#{CONFIG[:auth_url]}/oauth/token?code=#{params[:code]}client_id=#{CONFIG[:client_id]}&client_secret=#{CONFIG[:client_secret]}"
    uri = URI.parse("#{CONFIG[:auth_url]}/oauth/token")
    query_values = {
      :client_id    => CONFIG[:client_id],
      :redirect_uri => CONFIG[:redirect_uri],
      :client_secret=> CONFIG[:client_secret],
      :code         => params[:code]
    }
    result = Faraday.post(uri.to_s)
    data = JSON.parse(result.body)
    @access_token = data['access_token']
    <<-EOE
    access_token = #{data['access_token']}
    <a href="#{$auth_url}/me.json?access_token=#{access_token}">Me!</a>
    EOE
  end

  get '/me' do
    if @access_token
      p [:me, @access_token]
      access_token_url = "#{$auth_url}/me.json?access_token=#{access_token}"
      result = Faraday.get(access_token_url.to_s)
      JSON.parse(result)
    else
      redirect '/'
    end
  end
  
end


# ExampleServer.run if $0 == __FILE__
