$stdout.sync = true
require "rubygems"
require 'bundler/setup'
require 'uri'
require 'cgi'
require 'sinatra'
require 'sinatra/synchrony'
require 'faraday'
require 'json'
require 'openssl'
require 'faraday_middleware'
require 'hashie/mash'
require 'faraday_middleware/response/mashify'
require 'faraday_middleware/response/rashify'
require 'pry'
load File.dirname(__FILE__)+"/att_api.rb"


CONFIG = { :api_endpoint  => "https://api.tfoundry.com",
           :auth_url      => (ENV['ATT_BASE_DOMAIN']    || "https://auth.tfoundry.com"),
           :client_id     => (ENV['ATT_CLIENT_ID']      || 'e6b0570f56904fe81022efd6afa1ec99'), 
           :client_secret => (ENV['ATT_CLIENT_SECRET']  || 'c68ae72a5c7aa68d'),
           :redirect_uri  => (ENV['ATT_REDIRECT_URI']   || 'http://localhost:4567/users/att/callback'),
           :scope         => CGI.escape('AccountDetails,NGLE,profile,locker')
         }

# FIXME, this is not secure
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class ExampleServer < Sinatra::Base
  register Sinatra::Synchrony  # can be removed if not needed or running on windows
  configure do
    enable :logging
    enable :inline_templates
    enable :sessions
  end

  attr_accessor :access_token
  
  def api(token=session[:access_token])
    @api ||= AttApi.new(token)
  end

  get '/' do
    url = "#{CONFIG[:auth_url]}/oauth/authorize?redirect_uri=#{CGI.escape(CONFIG[:redirect_uri])}&client_id=#{CONFIG[:client_id]}&scope=#{CONFIG[:scope]}&response_type=code"
    erb "<a href=\"#{url}\">#{url}</a>"
  end

  get '/users/att/callback' do
    p [:params, params ]
    access_token_url = "#{CONFIG[:auth_url]}/oauth/token?redirect_uri=#{CGI.escape(CONFIG[:redirect_uri])}&code=#{params[:code]}&client_id=#{CONFIG[:client_id]}&client_secret=#{CONFIG[:client_secret]}&grant_type=code"
    result = Faraday.post(access_token_url)
    p [:result, result]
    @access_token = JSON.parse(result.body)['access_token']
    session[:access_token] = @access_token
    erb <<-EOE
    <ul  data-role="listview" data-inset="false">
      <li><pre>#{result.body}</li>
      <li><a  data-ajax="false" href="#{CONFIG[:auth_url]}/me.json?access_token=#{access_token}">#{CONFIG[:auth_url]}/me.json?access_token=#{@access_token}</a></li>
      <li><a  data-ajax="false" data-rel="dialog" href='/profile?access_token=#{@access_token}'>my profile</a></li>
      <li><a  data-ajax="false" data-rel="dialog" href='/location?access_token=#{@access_token}'>my location</a></li>
      <li><a  data-ajax="false" data-rel="dialog" href='/api/locker/object/'>my Locker Objects</a></li>
      <li><a  data-ajax="false" data-rel="dialog" href='/api/AddressBook/contacts/'>my AddressBook</a></li>
      <li><a  data-ajax="false" data-rel="dialog" href='/get/accountdetails/wireless/account?access_token=#{@access_token}'>my Wireless Account Details</a></li>
    </ul>
    EOE
  end

  get '/profile' do
    if params[:access_token] 
      result = Faraday.get("#{CONFIG[:auth_url]}/me.json?access_token=#{params[:access_token]}")
      erb "<pre>#{JSON.pretty_generate(JSON.parse(result.body))}</pre>"
    else
      'no access_token'
    end
  end

  # use the access_token to make an api call
  get '/get/:service/:resource/:operation' do
    begin
      result = Faraday.get("#{CONFIG[:api_endpoint]}/a1/#{params[:service]}/#{params[:resource]}/#{params[:operation]}?access_token=#{params[:access_token]}")
      raise "ERROR: #{result.status}" unless result.success?
      erb "request_headers: <pre>#{result.request_headers}</pre><hr>
      Status: #{result.status}<br>
      Body:<pre>#{JSON.pretty_generate(JSON.parse(result.body))}</pre>"
    rescue Exception => e
      # binding.pry   
      erb "<pre>#{@result.body}</pre>"
    end    
  end
  
  # use the att_api class and access_token to make an api call
  get '/api/*' do
    p [:api_proxy_to, params[:splat].join]
    begin
      @result = api.get(params[:splat].join)      
    rescue Exception => e
      # binding.pry 
    end
    erb "<pre>#{@result.body}</pre>"
  end

  
  get '/location' do
    result = Faraday.get("#{CONFIG[:api_endpoint]}/a1/ngle/location?access_token=#{params[:access_token]}")
    if result.success?
      @geo = JSON.parse(result.body)
      p [:geo, @geo]
      @location = @geo[ "ns1.terminalLocationList"]["terminalLocation"]["currentLocation"]
      erb :location
    else
      erb "there was an error <pre>#{result.inspect}</pre><br>body:<pre>#{result.body}</pre>"
    end
  end
  
  get '/logout' do
    session.each{|k,v| session.delete(k)}
    redirect '/'
  end
  
end


# ExampleServer.run if $0 == __FILE__


__END__

@@ layout
<html>
  <head>
    <link rel="stylesheet" href="http://code.jquery.com/mobile/1.1.0/jquery.mobile-1.1.0.min.css" />
    <script src="http://code.jquery.com/jquery-1.6.4.min.js"></script>
    <script src="http://code.jquery.com/mobile/1.1.0/jquery.mobile-1.1.0.min.js"></script>
    <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=true"></script>
    <script type="text/javascript" src="https://raw.github.com/HPNeo/gmaps/master/gmaps.js"></script>    
  </head>
  <body>
    <div data-role="page">

    	<div data-role="header">
    		<h1><a href='/'>Oauth Sample</a></h1>
    	</div><!-- /header -->

    	<div data-role="content">	
    		  <%= yield%>	
    	</div><!-- /content -->

    </div><!-- /page -->
  
  </body>
</html>

@@ location
<div id="map"></div>
<script type="text/javascript" charset="utf-8">
new GMaps({
  div: '#map',
  lat: <%= @location["latitude"]%>,
  lng: <%= @geo["longitude"]%>
});
</script>