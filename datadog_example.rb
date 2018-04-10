# This is a rewrite of the flask example from the README.
# With sinatra and ruby, instead of python

require 'sinatra'
require 'ddtrace'
require 'ddtrace/contrib/sinatra/tracer'
require 'byebug'

Datadog.configure do |c|
  c.use :sinatra
end

get '/' do
  "Entrypoint to the Application"
end

get '/api/apm' do
  "Getting APM Started"
end

get '/api/trace' do
  "Posting Traces"
end

# http://sinatrarb.com/
