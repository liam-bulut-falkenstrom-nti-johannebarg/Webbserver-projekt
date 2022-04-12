require 'sinatra'
# require 'sqlite3'
require 'slim'

enable :sessions

get('/')  do
    slim(:pokemons)
end 

post('/register') do


get('/register')  do
    slim(:register)
end 

get('/login')  do
    slim(:login)
end 