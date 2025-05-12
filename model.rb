require 'sinatra'
require 'sinatra/flash'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

def set_error(msg)
  flash[:notice] = msg
end

def connect_to_db(filepath)
  return SQLite3::Database.new(filepath)
end

# Users

# Register
def create_password(password)
  return BCrypt::Password.create(password)
end
def register_user(username, password, permission)
  password_digest = create_password(password)

  db = connect_to_db("db/database.db")
  db.execute("INSERT INTO users (username, password_digest, permission) VALUES (?, ?, ?)", [username, password_digest, permission])
end
def username_available?(username)
  db = connect_to_db("db/database.db")
  result = db.execute("SELECT id FROM users WHERE username=?", username)

  if result.empty?
    return true
  else
    return false
  end
end

# Login
def get_user_credentials(username, filepath)
  db = connect_to_db(filepath)
  db.results_as_hash = true
  return db.execute("SELECT id, password_digest, permission FROM users WHERE username = ?", [username])
end
def get_user_credentials_from_id(user_id, filepath)
  db = connect_to_db(filepath)
  db.results_as_hash = true
  return db.execute("SELECT permission FROM users WHERE id = ?", [user_id])
end
def password_matches?(result, password)
  pwdigest = result.first["password_digest"]

  if BCrypt::Password.new(pwdigest) == password
    return true
  else
    return false
  end
end

# Timers

def index_timers(user_id, filepath)
  db = connect_to_db(filepath) 
  db.results_as_hash = true

  custom_timers_result = db.execute("SELECT * FROM custom_timers WHERE user_id = ?", user_id)
  default_timers_result = db.execute("SELECT * FROM default_timers")

  return custom_timers_result, default_timers_result
end

def create_custom_timers(name, hour, minute, user_id, filepath)
  db = connect_to_db(filepath)
  db.execute("DELETE FROM custom_timers WHERE hour = ? AND minute = ? AND user_id = ?", [hour, minute, user_id])
  db.execute("INSERT INTO custom_timers (name, hour, minute, user_id) VALUES (?, ?, ?, ?)", [name, hour, minute, user_id])
end
def select_custom_timers(hour, minute, user_id, filepath)
  db = connect_to_db(filepath)
  db.results_as_hash = true
  return db.execute("SELECT * FROM custom_timers WHERE hour = ? AND minute = ? AND user_id = ?", [hour, minute, user_id]).first
end
def update_custom_timers(hour, minute, name, currentHour, currentMinute, user_id, filepath)
  db = connect_to_db(filepath)
  db.results_as_hash = true
  db.execute("UPDATE custom_timers SET hour = ?, minute = ?, name = ? WHERE hour = ? AND minute = ? AND user_id = ?", [hour, minute, name, currentHour, currentMinute, user_id])
end
def delete_custom_timers(hour, minute, user_id, filepath)
  db = connect_to_db(filepath)
  
  db.execute("DELETE FROM custom_timers WHERE hour = ? AND minute = ? AND user_id = ?", [hour, minute, user_id])
end

def create_default_timers(name, hour, minute, filepath)
  db = connect_to_db(filepath)
  db.execute("INSERT INTO default_timers (name, hour, minute) VALUES (?, ?, ?)", [name, hour, minute])
end
def select_default_timers(hour, minute, filepath)
  db = connect_to_db(filepath)
  db.results_as_hash = true
  return db.execute("SELECT * FROM default_timers WHERE hour = ? AND minute = ?", [hour, minute]).first
end
def update_default_timers(hour, minute, name, currentHour, currentMinute, filepath)
  db = connect_to_db(filepath)
  db.results_as_hash = true
  db.execute("UPDATE default_timers SET hour = ?, minute = ?, name = ? WHERE hour = ? AND minute = ?", [hour, minute, name, currentHour, currentMinute])
end
def delete_default_timers(hour, minute, filepath)
  db = connect_to_db(filepath)
  db.execute("DELETE FROM default_timers WHERE hour = ? AND minute = ?", [hour, minute])
end

def split_params(params)
  params.split("X")
end