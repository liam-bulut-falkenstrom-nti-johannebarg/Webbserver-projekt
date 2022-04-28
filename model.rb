module Model
    # fetches the paths of multiple routes
    #
    # @param [String] routes Name of all chosen routes
    #
    # @return [String] containing all paths to chosen routes
    def all_of(*strings)
        return /(#{strings.join("|")})/
    end

    # Inserts time of login and ip-address of user into database
    #
    # @param [String] time Time and date of login try
    # @param [String] ip Ip-adress of user
    #       
    def logging(time, ip_address)
        db = SQLite3::Database.new('db/database.db')
        db.execute("INSERT INTO logging (ip, time) VALUES (?,?)", ip_address, time)
    end
    
    # creates a variable and connects it to the database
    #
    # @param [String] path The path to the database, in this case: 'db/database.db'
    #
    # @return [Database] accessed through created variable 'db'
    def connect_to_db(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    # Checks if username already exists in the database
    #
    # @option params [String] username The name of the account the user put in to register/login
    #
    # @return [String] 
    # @return [nil] if name does not exist in database already
    def username_validation(username)
        db = connect_to_db('db/database.db')
        users_hash = db.execute("SELECT * FROM users WHERE username = ?", username).first
        if users_hash == nil
            return nil
        else 
            return username
        end
    end


    # Checks if user can log in or not
    #
    # @option params [String] username The username
    # @option params [String] password The password
    #
    # @return [String] The username of the now logged in account
    # @return [nil] if credentials do not match a user
    def login_user(username, password)
        db = connect_to_db('db/database.db')
        users_hash = db.execute("SELECT * FROM users WHERE username = ?", username).first

        user_id = users_hash["id"]
        digested_password = users_hash["password_digest"]
        if BCrypt::Password.new(digested_password) == password
            return username
        else
            return nil
        end
    end
    
    # Attempts to insert a new row in the users table
    #
    # @option params [String] username The username
    # @option params [String] password The password
    # @option params [String] confirmed_password The confirmed password
    #
    # @return [String] The name of the registered user
    # @return [nil] if the confirmed password does not match password 
    def register_user(username, password, confirmed_password)
        db = connect_to_db('db/database.db')
        if confirmed_password == password
            password_digest = BCrypt::Password.create(confirmed_password)
            db.execute("INSERT INTO users (username, password_digest) VALUES (?,?)", username, password_digest)
            return username
        else
            return nil
        end
    end

    # Searches for all pokemons that has the specified type 
    #
    # @option params [String/nil] type The type of the pokemon user wants displayed. Could also be nil or "all" if user wants to see all pokemons
    #
    # @return [Array] containing hashes for each searched pokemons
        #   * :id [Integer] pokemon id
        #   * :name [String] the name of the pokemon
    def filter_pokemon(filter)
        db = connect_to_db('db/database.db')
        if filter == "all" || filter == nil
            return db.execute("SELECT * FROM pokemon")
        else
            return db.execute("SELECT pokemon.id, pokemon.name FROM ((pokemon INNER JOIN pkmn_type_relation ON pkmn_type_relation.pkmn_id = pokemon.id) INNER JOIN type ON type.id = pkmn_type_relation.type_id) WHERE type_name = ?", filter)
        end
    end

    # Selects the specified pokemon and its types 
    #
    # @param [Integer] pokemon_id The id of specified pokemon
    #
    # @return [Array] with pokemon_hash and type_hash_array
    #   * :id [Integer] pokemon id
    #   * :name [String] the name of the pokemon
    #   * :id [Integer] type id
    #   * :type_name [String] the name of the type
    def get_pokemons_and_types(pokemon_id)
        db = connect_to_db('db/database.db')
    
        type_hash_array = db.execute("SELECT type.id, type.type_name FROM pkmn_type_relation INNER JOIN type ON type.id = pkmn_type_relation.type_id WHERE pkmn_id = ?", pokemon_id)
    
        pokemon_hash = db.execute("SELECT * FROM pokemon WHERE id = ?", pokemon_id).first
        return [pokemon_hash, type_hash_array]
    end

    # Inserts new record in team table 
    #
    # @param [String] team_name The name of specified team
    # @param [Array] added_pokemon_id_array The array with the id of which pokemon to add to the team
    # @param [String] user_name The name of the team owner
    #
    def new_team(team_name, added_pokemon_id_array, user_name)
        db = connect_to_db('db/database.db')
        user_id = db.execute("SELECT id FROM users WHERE username = ?", user_name).first["id"]
        db.execute("INSERT INTO team (team_name, user_id) VALUES (?,?)", team_name, user_id)
        team_id = db.execute("SELECT id FROM team WHERE team_name = ?", team_name).first["id"]
        added_pokemon_id_array.each do |added_pokemon_id|
            db.execute("INSERT INTO team_pkmn_relation (team_id, pkmn_id) VALUES (?,?)", team_id, added_pokemon_id)
        end
    end

    # Deletes row from team table 
    #
    # @param [Integer] team_id The id of a specified team
    #
    def delete_team(team_id)
        db = SQLite3::Database.new('db/database.db')
        db.execute("DELETE FROM team_pkmn_relation WHERE team_id = ?", team_id)
        db.execute("DELETE FROM team WHERE id = ?", team_id)
    end

    # Attempts to update a row in the team table
    #
    # @param [Integer] team_id The id of a specified team
    # @param [String] new_team_name The new name of a specified team
    #
    def update_team(team_id, new_team_name)
        db = SQLite3::Database.new('db/database.db')
        db.execute("UPDATE team SET team_name = ? WHERE id = ?", new_team_name, team_id)
    end

    # fetches information from team table 
    #
    # @param [Integer] team_id The id of a specified team
    #
    # @return [Hash]
    #   * :id [Integer] team id
    #   * :team_name [String] the name of the team
    #   * :user_id [Integer] the id of the user who owns that specific team
    def get_team_hash(team_id)
        db = connect_to_db('db/database.db')
        team_hash = db.execute("SELECT * FROM team WHERE id = ?", team_id).first
        return team_hash
    end

    # fetches information about user, team and the pokemon on the teams from the database 
    #
    # @param [String] username The name of logged in user
    #
    # @return [Array] with other arrays containing information about user, teams and pokemons on the teams
    #   * :id [Integer] user id
    #   * :username [String] the name of the logged in user
    #   * :id [Integer] the id of the team
    #   * :team_name [String] the name of the team
    #   * :name [String] the name of a pokemon on a team
    def get_team(username)
        db = connect_to_db('db/database.db')
        if username == "Admin"
            user_hash_array = db.execute("SELECT id, username FROM users WHERE username != ?", username) 
        else
            user_hash_array = db.execute("SELECT id, username FROM users WHERE username = ?", username)
        end
    
        team_hash_nested_array = []
        user_hash_array.each do |user_hash|
            team_hash_nested_array << db.execute("SELECT id, team_name FROM team WHERE user_id = ?", user_hash["id"])
        end
    
        team_pokemon_name_hash_nested_array = []
        team_hash_nested_array.each do |team_hash_array|
            temp_array = []
            team_hash_array.each do |team_hash|
                temp_array << db.execute("SELECT pokemon.name FROM team_pkmn_relation INNER JOIN pokemon ON team_pkmn_relation.pkmn_id = pokemon.id WHERE team_id = ?", team_hash["id"])
            end
            team_pokemon_name_hash_nested_array << temp_array
        end
        return [user_hash_array, team_hash_nested_array, team_pokemon_name_hash_nested_array]
    end

    # fetches username of owner of a specified team
    #
    # @param [Integer] team_id The id of a specified team
    #
    # @return [String] username
    def get_user_name(team_id)
        db = connect_to_db('db/database.db')
        user_name = db.execute("SELECT username FROM team INNER JOIN users ON users.id = team.user_id WHERE team.id = ?", team_id).first["username"]
        return user_name
    end


end