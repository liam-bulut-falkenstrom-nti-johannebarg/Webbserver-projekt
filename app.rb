require 'sinatra'
require 'sqlite3'
require 'slim'

get('/')  do
    slim(:start)
end 