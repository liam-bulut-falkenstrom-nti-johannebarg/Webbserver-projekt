require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'
require_relative './model.rb' 

enable :sessions

include Model

# Ska jag ha med update??? jaaaaaaa

before('/teams/') do
    if session[:logged_in_user] == nil 
        slim(:"/teams/index", locals:{username: session[:logged_in_user], added_pokemon_id_array: nil, team_hash_array: nil, team_pokemon_name_hash_nested_array: nil})
    end
end

before('/teams/:id/delete') do
    user_name = get_user_name(params[:id])
    if user_name != session[:logged_in_user] && session[:logged_in_user] != "Admin"
        redirect('/error/User_does_not_have_permission_to_delete_this_team')
    end
end

before('/teams') do
    if session[:logged_in_user] == nil
        redirect('/error/You_need_to_log_in_to_add_teams')
    end
    if session[:added_pkmns] == nil
        redirect('/error/Please_choose_at_least_one_Pokemon')
    end
    if params[:team_name].length == 0
        redirect('/error/Please_name_your_team')
    end
end

#kanske har alla errorchecks som before-block typ som register grejen

get('/')  do
    redirect('/pokemons/')
end



get('/pokemons/')  do
    filter = params[:filter]

    pokemon_array_hash = filter_pokemon(filter)

    slim(:"/pokemons/index", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns], pokemon_array_hash: pokemon_array_hash})
end 


get('/pokemons/:id') do

    output_array = get_pokemons_and_types(params[:id])

    slim(:"/pokemons/show", locals:{username: session[:logged_in_user], pokemon_hash: output_array[0], type_hash_array: output_array[1], added_pokemon_id_array: session[:added_pkmns]})
end



get('/teams/') do
    output_array = get_team(session[:logged_in_user])

    slim(:"/teams/index", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns], user_hash_array: output_array[0], team_hash_nested_array: output_array[1], team_pokemon_name_hash_nested_array: output_array[2]})
end 


get('/teams/new') do
    slim(:"/teams/new", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns]})
end


get('/teams/:id/edit') do
    team_id = params[:id]
    team_hash = get_team_hash(team_id)
    slim(:"/teams/edit", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns], team_hash: team_hash})
end

post('/photos/:id/update') do
    team_id = params[:id]
    new_team_name = params[:new_team_name]
    update_team(team_id, new_team_name)

    redirect('/teams/')
end

post('/teams') do
    team_name = params[:team_name]
    added_pokemon_id_array = session[:added_pkmns]

    session[:added_pkmns] = new_team(team_name, added_pokemon_id_array, session[:logged_in_user])

    redirect('/teams/')
end


post('/teams/:id/delete') do
    team_id = params[:id].to_i

    delete_team(team_id)

    redirect('/teams/')
end



get('/users/login')  do
    slim(:"/users/login", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns]}) #Måste man ha locals på alla??
end


post('/users/login') do    
    username = params[:username]
    password = params[:password]

    session[:logged_in_user] = login_user(username, password)

    redirect('/pokemons/')
end


get('/users/new')  do
    slim(:"/users/new", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns]})
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
    slim(:error, locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns], error_message: error_message})
end

# TODO: kanske lägga till förmåga för Admin att ta bort registrerade accounts