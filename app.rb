require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'

enable :sessions

get('/')  do
    redirect('/pokemons/')
end

get('/pokemons/')  do
    filter = params[:filter]
    pokemon_array_hash = []
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    if filter == "all" || filter == nil
        pokemon_array_hash = db.execute("SELECT * FROM pokemon")
    else
        type_id = db.execute("SELECT id FROM type WHERE type_name = ?", filter).first["id"]
        pkmn_id_hash_array = db.execute("SELECT pkmn_id FROM pkmn_type_relation WHERE type_id = ?", type_id)
        pkmn_id_hash_array.each do |pkmn_id_hash|
            pokemon_array_hash << db.execute("SELECT * FROM pokemon WHERE id = ?", pkmn_id_hash["pkmn_id"]).first
        end
    end
    slim(:"/pokemons/index", locals:{logged_in_user: session[:id], added_pokemon_id_array: session[:added_pkmns], pokemon_array_hash: pokemon_array_hash}) #Kanske låta session innehålla username också?
end 

post('/users') do
    username = params[:username]
    password = params[:password]
    confirmed_password = params[:confirmed_password]
    
    db = SQLite3::Database.new('db/database.db')
    if db.execute("SELECT username FROM users WHERE username = ?", username).first != nil
        "användarnamnet finns redan" #Undrar om man får använda sessions här eller finns det smartare lösning??? Kanske skicka till error screen bara
    elsif confirmed_password == password
        password_digest = BCrypt::Password.create(confirmed_password)
        db.execute("INSERT INTO users (username, password_digest) VALUES (?,?)", username, password_digest)
        redirect('/users/new')
    else
        "lösenorden matchar ej"
    end
end

get('/teams/new') do
    slim(:"/teams/new", locals:{logged_in_user: session[:id], added_pokemon_id_array: session[:added_pkmns]})
end

post('/teams') do
    team_name = params[:team_name]
    added_pokemon_id_array = session[:added_pkmns]
    db = SQLite3::Database.new('db/database.db')
    p session[:id]
    p team_name
    p added_pokemon_id_array
    db.execute("INSERT INTO team (team_name, user_id) VALUES (?,?)", team_name, session[:id])
    team_id = db.execute("SELECT id FROM team WHERE team_name = ?", team_name).first[0]
    p team_id
    added_pokemon_id_array.each do |added_pokemon_id|
        db.execute("INSERT INTO team_pkmn_relation (team_id, pkmn_id) VALUES (?,?)", team_id, added_pokemon_id)
    end
    session[:added_pkmns] = nil
    redirect('/pokemons/')
end

post('/teams/:id/delete') do
    team_id = params[:id].to_i
    p team_id
    db = SQLite3::Database.new('db/database.db')
    db.execute("DELETE FROM team_pkmn_relation WHERE team_id = ?", team_id)
    db.execute("DELETE FROM team WHERE id = ?", team_id)
    redirect('/teams/')
end

get('/teams/') do

    user_id = session[:id]
    p user_id
    if user_id == nil 
        slim(:"/teams/index", locals:{logged_in_user: user_id, added_pokemon_id_array: nil, team_hash_array: nil, array_with_all_team_pokemon_hashes: nil})
    else
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        username = db.execute("SELECT username FROM users WHERE id = ?", user_id).first["username"]
        p username
        team_hash_array = db.execute("SELECT id, team_name FROM team WHERE user_id = ?", user_id)
        p team_hash_array
           
        team_pokemon_id_hash_array = []
        team_hash_array.each do |team_hash|
            team_pokemon_id_hash_array << db.execute("SELECT pkmn_id FROM team_pkmn_relation WHERE team_id = ?", team_hash["id"])
        end        

        array_with_all_team_pokemon_hashes = []
        team_pokemon_id_hash_array.each do |array_with_team_pokemon_ids|
            temp_array = []
            array_with_team_pokemon_ids.each do |pokemon_hash|
                temp_array << db.execute("SELECT * FROM pokemon WHERE id = ?", pokemon_hash["pkmn_id"]).first
            end
            array_with_all_team_pokemon_hashes << temp_array
        end

        p array_with_all_team_pokemon_hashes
        slim(:"/teams/index", locals:{logged_in_user: username, added_pokemon_id_array: session[:added_pkmns], team_hash_array: team_hash_array, array_with_all_team_pokemon_hashes: array_with_all_team_pokemon_hashes})
        
    end
end 

get('/users/new')  do
    slim(:"/users/new", locals:{logged_in_user: session[:id], added_pokemon_id_array: session[:added_pkmns]})
end 

post('/users/login') do
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
        redirect('/pokemons/')
    else
        "fel lösenord"
    end
end

get('/users/login')  do
    slim(:"/users/login", locals:{logged_in_user: session[:id], added_pokemon_id_array: session[:added_pkmns]}) #Måste man ha locals på alla??
end 

get('/destroy') do
    session.destroy
    redirect('/pokemons/')
end

get('/add/:pkmn_id') do
    if session[:added_pkmns] == nil
        session[:added_pkmns] = []
    end
    session[:added_pkmns] << params[:pkmn_id].to_i
    redirect('/pokemons/')
end

get('/cancel') do
    session[:added_pkmns] = nil
    redirect('/pokemons/')
end

get('/pokemons/:id') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    type_id_hash_array = db.execute("SELECT type_id FROM pkmn_type_relation WHERE pkmn_id = ?", params[:id])
    type_hash_array = []
    type_id_hash_array.each do |type_id_hash|
        type_hash_array << db.execute("SELECT type_name FROM type WHERE id = ?", type_id_hash["type_id"]).first
    end
    
    pokemon_hash = db.execute("SELECT * FROM pokemon WHERE id = ?", params[:id]).first # Finns det bättre sätt att göra detta på?
    slim(:"/pokemons/show", locals:{logged_in_user: session[:id], pokemon_hash: pokemon_hash, type_hash_array: type_hash_array, added_pokemon_id_array: session[:added_pkmns]})
end