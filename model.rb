
# Ska man ha alla alla funktioner här? 

module Model

    def connect_to_db(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

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

    def login_user(username, password)
        db = connect_to_db('db/database.db')
        users_hash = db.execute("SELECT * FROM users WHERE username = ?", username).first
        if users_hash == nil
            redirect('/error/User_does_not_exist')
        else
            user_id = users_hash["id"]
            digested_password = users_hash["password_digest"]
            if BCrypt::Password.new(digested_password) == password
                session[:id] = user_id
            else
                redirect('/error/Wrong_password')
            end
        end
    end

    def register_user(username, password, confirmed_password)
        db = connect_to_db('db/database.db')
        if db.execute("SELECT username FROM users WHERE username = ?", username).first != nil
            redirect('/error/Username_already_exists')
        elsif confirmed_password == password
            password_digest = BCrypt::Password.create(confirmed_password)
            db.execute("INSERT INTO users (username, password_digest) VALUES (?,?)", username, password_digest)
        else
            redirect('/error/Passwords_do_not_match')
        end
    end

    def filter_pokemon(filter)
        db = connect_to_db('db/database.db')
        if filter == "all" || filter == nil
            return db.execute("SELECT * FROM pokemon")
        else
            return db.execute("SELECT pokemon.id, pokemon.name FROM ((pokemon INNER JOIN pkmn_type_relation ON pkmn_type_relation.pkmn_id = pokemon.id) INNER JOIN type ON type.id = pkmn_type_relation.type_id) WHERE type_name = ?", filter)
        end
    end

    def new_team(team_name, added_pokemon_id_array)
        db = SQLite3::Database.new('db/database.db')
        db.execute("INSERT INTO team (team_name, user_id) VALUES (?,?)", team_name, session[:id])
        team_id = db.execute("SELECT id FROM team WHERE team_name = ?", team_name).first[0]
        added_pokemon_id_array.each do |added_pokemon_id|
            db.execute("INSERT INTO team_pkmn_relation (team_id, pkmn_id) VALUES (?,?)", team_id, added_pokemon_id)
        end
        session[:added_pkmns] = nil
    end

    def delete_team(team_id)
        db = SQLite3::Database.new('db/database.db')
        db.execute("DELETE FROM team_pkmn_relation WHERE team_id = ?", team_id)
        db.execute("DELETE FROM team WHERE id = ?", team_id)
    end

    # def get_pokemon/get_team(params)

end