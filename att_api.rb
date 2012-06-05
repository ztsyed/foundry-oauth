require "rubygems"
require 'cgi'
require 'bundler'
Bundler.setup
require 'eventmachine'
require "em-synchrony"
require "em-synchrony/em-http"
require 'faraday'
require 'json'
require 'openssl'
require 'faraday_middleware'
require 'hashie/mash'
require 'faraday_middleware/response/mashify'
require 'faraday_middleware/response/rashify'
require 'pry'

class AttApi   
  API_ENDPOINT = ENV['ATT_API_ENDPOINT'] || 'https://api.tfoundry.com'
  attr_reader :connection
  attr_accessor :config, :access_token
  
  def self.default_config(opts={})
     {  :auth_url      => (ENV['ATT_BASE_DOMAIN']    || "https://auth.tfoundry.com"),
        :client_id     => (ENV['ATT_CLIENT_ID']      || 'e6b0570f56904fe81022efd6afa1ec99'), 
        :client_secret => (ENV['ATT_CLIENT_SECRET']  || 'c68ae72a5c7aa68d'),
        :redirect_uri  => (ENV['ATT_REDIRECT_URI']   || 'http://localhost:4567/auth/att/callback'),
        :scope         => CGI.escape('AccountDetails,NGLE,profile,locker'),
        :response_type => 'authorization_code',
        :connection_options => {}
      }
  end

  def initialize(config, version='a1', opts={})
    config = self.class.default_config.merge(opts)
    faraday_opts = { :timeout      => 20,
                     :open_timeout => 20  
                    # :ssl => { :ca_file => '/usr/lib/ssl/certs/ca-certificates.crt', :ca_path => "/usr/lib/ssl/certs", :verify=>false}
                    }.merge(config[:connection_options])
                #replace ssl option with this to avoid validatoin, #{verify: false}  
    @access_token = config[:token] if config[:token]
    @connection ||= begin
      conn = Faraday::Connection.new "#{API_ENDPOINT}/#{version}/", faraday_opts do |c|   
       c.request :json
       # c.request  :retry
       # c.response :logger
       c.response :json
       c.response :rashify
       # c.adapter :em_http
      end
       conn.headers['User-Agent'] = 'Faraday'
       # conn.headers['Authorization'] = "Bearer #{token}"  #TODO:  
      conn.params['access_token'] = @access_token unless @access_token.nil?
      conn
    end
  end
  
  
  def authorize_url(opts={})
    options=config.merge opts
    url = "#{options[:auth_url]}/oauth/authorize?redirect_uri=#{CGI.escape(options[:redirect_uri])}&client_id=#{options[:client_id]}&scope=#{options[:scope]}&response_type=#{options[:response_type]}"
  end
  
  def retrieve_access_token(code, opts={})
    options=config.merge opts
    access_token_url = "#{options[:auth_url]}/oauth/token?redirect_uri=#{CGI.options(config[:redirect_uri])}&code=#{options[:code]}&client_id=#{options[:client_id]}&client_secret=#{options[:client_secret]}&grant_type=#{options[:response_type]}"
    result = Faraday.post(access_token_url)
    con
  end
  
  def get(path, options={}, &blk)
    @connection.get(path, options, &blk)
  end
  
  def post(path, options={}, &blk)
    @connection.get(path, options, &blk)
  end

  def put(path, options={}, &blk)
    @connection.get(path, options, &blk)
  end

  def delete(path, options={}, &blk)
    @connection.get(path, options, &blk)
  end
  
  # [:post, :put, :delete, :head, :patch, :options].each do |meth|
  #    define_method(meth) {|path, *args, &blk| @connection.send(meth, path, *args, &blk) }
  # end
end
