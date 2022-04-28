require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'
require_relative './model.rb' 

enable :sessions

include Model

# Checks if user is logged in. If not, redirects to '/error/:error_message'
#
before('/teams/') do
    if session[:logged_in_user] == nil 
        slim(:"/teams/index", locals:{username: session[:logged_in_user], added_pokemon_id_array: nil, team_hash_array: nil, team_pokemon_name_hash_nested_array: nil})
    end
end

# Checks if the correct user is sending a request to delete a team. If not, redirects to '/error/:error_message'
#
# @param [Integer] team_id, id of team user wants to delete
#
# @see Model#get_user_name
before('/teams/:id/delete') do
    user_name = get_user_name(params[:id])
    if user_name != session[:logged_in_user] && session[:logged_in_user] != "Admin"
        redirect('/error/User_does_not_have_permission_to_delete_this_team')
    end
end

# Checks if user is logged in, if user has chosen any pokemon for the new team and if user has chosen a name for the team that is going to be created. If not, redirects to '/error/:error_message'
#
before('/teams') do
    if session[:logged_in_user] == nil
        redirect('/error/You_need_to_log_in_to_add_teams')
    elsif session[:added_pkmns] == nil
        redirect('/error/Please_choose_at_least_one_Pokemon')
    elsif params[:team_name].length == 0
        redirect('/error/Please_name_your_team')
    end
end

# Checks if username exists in database as a user, checks if user is trying to log in too fast. If an error is detected, redirects to '/error/:error_message'
#
# @param [String] username, name of user trying to log in.
#
# @see Model#username_validation
before('/users/login_user') do
    username = params[:username]
    if session[:logging] != nil
        if Time.now - session[:logging] < 10
            redirect('/error/Logging_in_too_fast._Please_try_again_later!')
        end
    end
    if username_validation(username) == nil
        redirect('/error/User_does_not_exist')
    end
end

# Checks if username trying to be registered already exists in the database. If not, redirects to '/error/:error_message'
#
# @param [String] username, name of user requested to be registered.
#
# @see Model#username_validation
before('/users/new') do
    username = params[:username]
    if username_validation(username) != nil
        redirect('/error/Username_already_exists')
    end
end

# Checks if user is logged in, if logged in user has permission to update the chosen team and if user has chosen a new name for the team. If not, redirects to '/error/:error_message'
#
# @param [String] username, name of user requested to be registered.
#
# @see Model#username_validation
before('/teams/:id/update') do
    new_team_name = params[:new_team_name]
    team_id = params[:id]
    username = get_user_name(team_id)
    if session[:logged_in_user] == nil
        redirect('/error/You_need_to_log_in_to_change_team_name')
    elsif session[:logged_in_user] != username
        redirect('/error/This_user_does_not_have_permission_to_change_name_of_this_team')
    elsif new_team_name.length == 0
        redirect('/error/Please_choose_a_name_for_your_team')
    end
end

# redirects to '/pokemons/' after requesting the specified routes
#
after all_of('/', '/destroy', '/cancel') do
    redirect('/pokemons/')
end

# logs users ip adress and time of logging in after user tries to log in and '/users/login_user' is requested
#
# @see Model#logging
after('/users/login_user') do
    ip_address = @env['REMOTE_ADDR']
    time = Time.new
    time_string = "#{time.year}/#{time.month}/#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
    logging(ip_address, time_string)
end

# Displays pokemon stored in the database. Can be filtered by pokemon type
#
# @param [String] filter, name of type. Filters after type.
#
# @see Model#filter_pokemon
get('/pokemons/')  do
    filter = params[:filter]

    pokemon_array_hash = filter_pokemon(filter)

    slim(:"/pokemons/index", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns], pokemon_array_hash: pokemon_array_hash})
end 

# Displays a single pokemon stored in the database
#
# @param [Integer] pokemon_id, id of pokemon used to specifiy pokemon in database.
#
# @see Model#get_pokemons_and_types
get('/pokemons/:id') do
    output_array = get_pokemons_and_types(params[:id])

    slim(:"/pokemons/show", locals:{username: session[:logged_in_user], pokemon_hash: output_array[0], type_hash_array: output_array[1], added_pokemon_id_array: session[:added_pkmns]})
end

# Displays user teams stored in the database. Displays all user's teams if user is logged in as Admin
#
# @see Model#get_team
get('/teams/') do
    output_array = get_team(session[:logged_in_user])

    slim(:"/teams/index", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns], user_hash_array: output_array[0], team_hash_nested_array: output_array[1], team_pokemon_name_hash_nested_array: output_array[2]})
end 

# Displays a form where user names team they are adding to the database
#
get('/teams/new') do
    slim(:"/teams/new", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns]})
end

# Displays a form where user can choose new name for an owned team.
#
# @param [Integer] team_id, id of team that is going to be updated.
#
# @see Model#get_team_hash
get('/teams/:id/edit') do
    team_id = params[:id]
    team_hash = get_team_hash(team_id)
    slim(:"/teams/edit", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns], team_hash: team_hash})
end

# Updates team name with the new team name
#
# @param [Integer] team_id, id of team that is going to be updated.
# @param [String] new_team_name, id of team that is going to be updated.
#
# @see Model#update_team
post('/teams/:id/update') do
    team_id = params[:id]
    new_team_name = params[:new_team_name]
    update_team(team_id, new_team_name)
    redirect('/teams/')
end

# Adds new team in database
#
# @param [String] team_name, name of team that is going to be added.
#
# @see Model#new_team
post('/teams') do
    team_name = params[:team_name]
    added_pokemon_id_array = session[:added_pkmns]

    new_team(team_name, added_pokemon_id_array, session[:logged_in_user])
    session[:added_pkmns] = nil
    redirect('/teams/')
end

# Deletes a specified team record from database
#
# @param [Integer] team_id, id of team that is going to be deleted.
#
# @see Model#delete_team
post('/teams/:id/delete') do
    team_id = params[:id].to_i
    delete_team(team_id)
    redirect('/teams/')
end

# Display a form used to log in
#
get('/users/login')  do
    slim(:"/users/login", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns]})
end

# Logs in user if password is correct and logs the time of logging in.
#
# @param [String] username, username user typed in
# @param [String] password, password user typed in
#
# @see Model#login_user
post('/users/login_user') do    
    username = params[:username]
    password = params[:password]
    session[:logging] = Time.now
    session[:logged_in_user] = login_user(username, password)
    if session[:logged_in_user] == nil
        redirect('/error/Wrong_password')
    else
        redirect('/pokemons/')
    end
   
end

# Displays a form where user can register an account
#
get('/users/new')  do
    slim(:"/users/new", locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns]})
end 

# Registers a new account if password and confirmed password match. If not it redirects to the '/error/:error_message' route
#
# @param [String] username, username user typed in
# @param [String] password, password user typed in
# @param [String] confirmed_password, same password user types in a second time to confirm their choice
#
# @see Model#register_user
post('/users/new') do
    username = params[:username]
    password = params[:password]
    confirmed_password = params[:confirmed_password]

    if register_user(username, password, confirmed_password) == nil
        redirect('/error/Passwords_do_not_match')
    else
        redirect('/users/new')
    end
end


# removes all data stored in session from logged in user.
#
get('/destroy') do
    session.destroy
end

# Add a pokemon to the :added_pkmns array stored in sessions. Stores which pokemon user has choosen for a new team. Makes sure user can onlu choose a maximum of 6 pokekom per team.
#
get('/add/:pkmn_id') do
    if session[:added_pkmns] == nil
        session[:added_pkmns] = []
    end
    if session[:added_pkmns].length == 6
        redirect('/error/Can_not_add_more_Pokemons_to_this_team')
    end
    session[:added_pkmns] << params[:pkmn_id].to_i
    redirect('/pokemons/')
end

# removes data from the :added_pkmns array stored in sessions. This route is requested when a standard user cancels their current team they are creating.
#
get('/cancel') do
    session[:added_pkmns] = nil
end

# Displays an error message when an error occurs. A route includes the error message in the params when redirecting to this route
#
# @param [String] error_message, the string that is to be displayed on screen but with underscores instead of spaces.
#
get('/error/:error_message') do
    error_message = params[:error_message].split("_").join(" ")
    slim(:error, locals:{username: session[:logged_in_user], added_pokemon_id_array: session[:added_pkmns], error_message: error_message})
end
