require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'

enable :sessions

get('/')  do
    filter = params[:filter] # Lägga till filter grejer här tackkkkkkkkkkkkkk
    pokemon_array_hash = []
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    if filter == "all"
        pokemon_array_hash = db.execute("SELECT * FROM pokemon")
    else
        type_id = db.execute("SELECT id FROM type WHERE type_name = ?", filter).first["id"]
        pkmn_id_hash_array = db.execute("SELECT pkmn_id FROM pkmn_type_relation WHERE type_id = ?", type_id)
        pkmn_id_hash_array.each do |pkmn_id_hash|
            pokemon_array_hash << db.execute("SELECT * FROM pokemon WHERE id = ?", pkmn_id_hash["pkmn_id"]).first
        end
    end
    slim(:pokemons, locals:{logged_in_user: session[:id], pokemon_array_hash: pokemon_array_hash}) #Kanske låta session innehålla username också?
end 

post('/users/new') do
    username = params[:username]
    password = params[:password]
    confirmed_password = params[:confirmed_password]
    
    db = SQLite3::Database.new('db/database.db')
    if db.execute("SELECT username FROM users WHERE username = ?", username).first != nil
        "användarnamnet finns redan" #Undrar om man får använda sessions här eller finns det smartare lösning??? Kanske skicka till error screen bara
    elsif confirmed_password == password
        password_digest = BCrypt::Password.create(confirmed_password)
        db.execute("INSERT INTO users (username, password_digest) VALUES (?,?)", username, password_digest)
        redirect('/register')
    else
        "lösenorden matchar ej"
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

get('/destroy') do
    session.destroy
    redirect('/')
end

get('/pokemon/:id') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    type_id_hash_array = db.execute("SELECT type_id FROM pkmn_type_relation WHERE pkmn_id = ?", params[:id])
    type_hash_array = []
    type_id_hash_array.each do |type_id_hash|
        type_hash_array << db.execute("SELECT type_name FROM type WHERE id = ?", type_id_hash["type_id"]).first
    end
    
    pokemon_hash = db.execute("SELECT * FROM pokemon WHERE id = ?", params[:id]).first # Finns det bättre sätt att göra detta på?
    slim(:show, locals:{logged_in_user: session[:id], pokemon_hash: pokemon_hash, type_hash_array: type_hash_array})
end