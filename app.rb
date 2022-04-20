require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'
require_relative './model.rb' 

enable :sessions

include Model

# Ska jag ha med update???

helpers do
    def username
        db = connect_to_db('db/database.db')
        if session[:id] != nil
            username = db.execute("SELECT username FROM users WHERE id = ?", session[:id]).first["username"]
        else
            username = nil
        end
        return username
    end
end
   
before('/teams/') do
    if username == nil 
        slim(:"/teams/index", locals:{user_id: session[:id], added_pokemon_id_array: nil, team_hash_array: nil, team_pokemon_name_hash_nested_array: nil})
    end
end

# before added pkmn array?
# är användaren inloggad? används den för typ

get('/')  do
    redirect('/pokemons/')
end



get('/pokemons/')  do
    filter = params[:filter]

    pokemon_array_hash = filter_pokemon(filter)

    slim(:"/pokemons/index", locals:{added_pokemon_id_array: session[:added_pkmns], pokemon_array_hash: pokemon_array_hash})
end 


get('/pokemons/:id') do
    db = connect_to_db('db/database.db')
    
    type_hash_array = db.execute("SELECT type.id, type.type_name FROM pkmn_type_relation INNER JOIN type ON type.id = pkmn_type_relation.type_id WHERE pkmn_id = ?", params[:id])

    pokemon_hash = db.execute("SELECT * FROM pokemon WHERE id = ?", params[:id]).first # Finns det bättre sätt att göra detta på?

    slim(:"/pokemons/show", locals:{pokemon_hash: pokemon_hash, type_hash_array: type_hash_array, added_pokemon_id_array: session[:added_pkmns]})
end



get('/teams/') do
    # db = connect_to_db('db/database.db')
    
    # if username == "Admin"
    #     user_hash_array = db.execute("SELECT id, username FROM users WHERE username != ?", username) 
    # else
    #     user_hash_array = db.execute("SELECT id, username FROM users WHERE username = ?", username)
    # end

    # team_hash_nested_array = []
    # user_hash_array.each do |user_hash|
    #     team_hash_nested_array << db.execute("SELECT id, team_name FROM team WHERE user_id = ?", user_hash["id"])
    # end

    # team_pokemon_name_hash_nested_array = []
    # team_hash_nested_array.each do |team_hash_array|
    #     temp_array = []
    #     team_hash_array.each do |team_hash|
    #         temp_array << db.execute("SELECT pokemon.name FROM team_pkmn_relation INNER JOIN pokemon ON team_pkmn_relation.pkmn_id = pokemon.id WHERE team_id = ?", team_hash["id"])
    #     end
    #     team_pokemon_name_hash_nested_array << temp_array
    # end

    output_array = get_team(username)

    slim(:"/teams/index", locals:{added_pokemon_id_array: session[:added_pkmns], user_hash_array: output_array[0], team_hash_nested_array: output_array[1], team_pokemon_name_hash_nested_array: output_array[2]})
end 


get('/teams/new') do
    slim(:"/teams/new", locals:{added_pokemon_id_array: session[:added_pkmns]})
end

post('/teams') do
    team_name = params[:team_name]
    added_pokemon_id_array = session[:added_pkmns]

    new_team(team_name, added_pokemon_id_array)

    redirect('/teams/')
end

post('/teams/:id/delete') do
    team_id = params[:id].to_i

    delete_team(team_id)

    redirect('/teams/')
end



get('/users/login')  do
    slim(:"/users/login", locals:{added_pokemon_id_array: session[:added_pkmns]}) #Måste man ha locals på alla??
end 

post('/users/login') do    
    username = params[:username]
    password = params[:password]

    login_user(username, password)

    redirect('/pokemons/')
end


get('/users/new')  do
    slim(:"/users/new", locals:{added_pokemon_id_array: session[:added_pkmns]})
end 

post('/users/new') do
    username = params[:username]
    password = params[:password]
    confirmed_password = params[:confirmed_password]

    register_user(username, password, confirmed_password)

    redirect('/users/new')

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

get('/error/:error_message') do
    error_message = params[:error_message].split("_").join(" ")
    slim(:error, locals:{added_pokemon_id_array: session[:added_pkmns], error_message: error_message})
end

# TODO: kanske lägga till förmåga för Admin att ta bort registrerade accounts