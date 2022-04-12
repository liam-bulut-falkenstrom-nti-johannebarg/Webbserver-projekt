require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'

enable :sessions

get('/')  do
    slim(:pokemons, locals:{logged_in_user: session[:id]}) #Kanske låta session innehålla username också?
end 

post('/users/new') do
    username = params[:username]
    password = params[:password]
    confirmed_password = params[:confirmed_password]
    
    db = SQLite3::Database.new('db/database.db')
    if db.execute("SELECT username FROM users WHERE username = ?", username).first != nil
        "användarnamnet finns redan" #Undrar om man får använda sessions här eller finns det smartare lösning???
    elsif confirmed_password == password
        password_digest = BCrypt::Password.create(confirmed_password)
        db.execute("INSERT INTO users (username, password_digest) VALUES (?,?)", username, password_digest)
        redirect('/register')
    else
        "lösenorden matchar ej" #Undrar om man får använda sessions här eller finns det smartare lösning???
    end
end

get('/register')  do
    slim(:register, locals:{logged_in_user: session[:id]})
end 

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    output = db.execute("SELECT * FROM users WHERE username = ?", username).first
    if output == nil
        "användaren finns inte"
    end
    id = output["id"]
    digested_password = output["password_digest"]
    if BCrypt::Password.new(digested_password) == password
        session[:id] = id
        redirect('/')
    else
        "fel lösenord"
    end
end

get('/login')  do
    slim(:login, locals:{logged_in_user: session[:id]}) #Måste man ha locals på alla??
end 