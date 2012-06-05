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
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE unless OpenSSL::SSL::VERIFY_PEER==OpenSSL::SSL::VERIFY_NONE

class ExampleServer < Sinatra::Base
  configure do
    enable :logging
    enable :inline_templates
    enable :sessions
  end

  attr_accessor :access_token

  get '/hi' do
    'hi'
  end

  get '/' do
    url = "#{CONFIG[:auth_url]}/oauth/authorize?redirect_uri=#{CGI.escape(CONFIG[:redirect_uri])}&client_id=#{CONFIG[:client_id]}&scope=profile&response_type=code"
    erb "<a href=\"#{url}\">#{url}</a>"
  end

  get '/auth/att/callback' do
    puts params
    access_token_url = "#{CONFIG[:auth_url]}/oauth/token?redirect_uri=#{CGI.escape(CONFIG[:redirect_uri])}&code=#{params[:code]}&client_id=#{CONFIG[:client_id]}&client_secret=#{CONFIG[:client_secret]}&grant_type=code"
    result = Faraday.post(access_token_url)
    p [:result, result]
    data = JSON.parse(result.body)
    @access_token = data['access_token']
    erb <<-EOE
    <ul  data-role="listview" data-inset="false">
      <li><pre>#{result.body}</li>
      <li><a  data-ajax="false" href="#{CONFIG[:auth_url]}/me.json?access_token=#{access_token}">#{CONFIG[:auth_url]}/me.json?access_token=#{@access_token}</a></li>
      <li><a  data-ajax="false" data-rel="dialog" href='/me?access_token=#{@access_token}'>me</a></li>
    </ul>
    EOE
  end

  get '/me' do
    if params[:access_token] 
      result = Faraday.get("#{CONFIG[:auth_url]}/me.json?access_token=#{params[:access_token]}")
      erb "<pre>#{JSON.pretty_generate(JSON.parse(result.body))}</pre>"
    else
      'no access_token'
    end
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
  </head>
  <body>
    <div data-role="page">

    	<div data-role="header">
    		<h1>Oauth Sample</h1>
    	</div><!-- /header -->

    	<div data-role="content">	
    		  <%= yield%>	
    	</div><!-- /content -->

    </div><!-- /page -->
    
      </div>
    </div>
  </body>
</html>