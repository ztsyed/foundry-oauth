$LOAD_PATH.unshift(File.dirname(__FILE__)+"/../lib/")
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rubygems"
require 'sinatra'
require 'oauth_example'

# log = File.new(File.dirname(__FILE__)+"/example_server.log", "a")
# $stdout.reopen(log)
# $stderr.reopen(log)

run ExampleServer