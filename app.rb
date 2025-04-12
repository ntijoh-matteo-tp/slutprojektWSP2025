require 'sinatra'
require 'sinatra/flash'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'tzinfo'

enable :sessions

def set_error(msg)
  flash[:notice] = msg
end

get('/') do
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  custom_timers_result = db.execute("SELECT * FROM custom_timers WHERE user_id = ?", session[:user_id])
  default_timers_result = db.execute("SELECT * FROM default_timers")
  #puts "hello eeadedqwqdwq #{default_timers_result}"

  if session[:user_id] == nil
    session[:permission] = "guest"
  end  

  puts "Perms: #{session[:permission]}"

  slim(:home, locals:{custom_timers:custom_timers_result, default_timers:default_timers_result})
end 

get('/default_timers/new/') do
  if session[:permission] != "admin"
    set_error("Permission denied")
    redirect("/")
  end

  slim(:"default_timers/new")
end 
post('/default_timers/new/') do
  name = params[:name]
  hour = 0
  minute = params[:minute]

  db = SQLite3::Database.new("db/database.db")
  db.execute("INSERT INTO default_timers (name, hour, minute) VALUES (?, ?, ?)", [name, hour, minute])
  redirect('/')
end
get('/default_timers/:time/edit/') do
  if session[:permission] != "admin"
    set_error("Permission denied")
    redirect("/")
  end

  hour = params[:time].split("X")[0]
  minute = params[:time].split("X")[1]

  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM default_timers WHERE hour = ? AND minute = ?", [hour, minute]).first
  puts "Results: #{result}"
  slim(:"/default_timers/edit", locals:{timer:result})
end 

post('/default_timers/:time/update/') do
  puts "Hello 2: #{params[:time]}"
  currentHour = params[:time].split("X")[0]
  currentMinute = params[:time].split("X")[1]
  name = params[:name]
  hour = params[:hour]
  minute = params[:minute]

  puts " Hello: #{[currentHour, currentMinute, name, hour, minute]}"
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  db.execute("UPDATE default_timers SET hour = ?, minute = ?, name = ? WHERE hour = ? AND minute = ?", [hour, minute, name, currentHour, currentMinute])
  redirect('/')
end

get('/timers/') do
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  custom_timers_result = db.execute("SELECT * FROM custom_timers WHERE user_id = ?", [session[:user_id]])

  slim(:"timers/index", locals:{custom_timers:custom_timers_result})
end

get('/timers/new/') do
  slim(:"timers/new")
end 

post('/timers/new/') do
  name = params[:name]
  hour = params[:hour]
  minute = params[:minute]
  user_id = session[:user_id]

  db = SQLite3::Database.new("db/database.db")
  db.execute("DELETE FROM custom_timers WHERE hour = ? AND minute = ? AND user_id = ?", [hour, minute, user_id])
  db.execute("INSERT INTO custom_timers (name, hour, minute, user_id) VALUES (?, ?, ?, ?)", [name, hour, minute, user_id])
  redirect('/timers/')
end 

post('/timers/:time/delete/') do
  hour = params[:time].split("X")[0]
  minute = params[:time].split("X")[1]
  user_id = session[:user_id]

  db = SQLite3::Database.new("db/database.db")
  db.execute("DELETE FROM custom_timers WHERE hour = ? AND minute = ? AND user_id = ?", [hour, minute, user_id])
  redirect('/timers/')
end 

post('/default_timers/:time/delete/') do
  hour = params[:time].split("X")[0]
  minute = params[:time].split("X")[1]

  db = SQLite3::Database.new("db/database.db")
  db.execute("DELETE FROM default_timers WHERE hour = ? AND minute = ?", [hour, minute])
  redirect('/')
end 

get('/timers/:time/edit/') do
  hour = params[:time].split("X")[0]
  minute = params[:time].split("X")[1]
  user_id = session[:user_id]

  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM custom_timers WHERE hour = ? AND minute = ? AND user_id = ?", [hour, minute, user_id]).first
  puts "Results: #{result}"
  slim(:"/timers/edit", locals:{timer:result})
end 

post('/timers/:time/update/') do
  currentHour = params[:time].split("X")[0]
  currentMinute = params[:time].split("X")[1]
  name = params[:name]
  hour = params[:hour]
  minute = params[:minute]
  id = session[:user_id]
  puts " Hello: #{[currentHour, currentMinute, name, hour, minute]}"
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  db.execute("UPDATE custom_timers SET hour = ?, minute = ?, name = ? WHERE hour = ? AND minute = ? AND user_id = ?", [hour, minute, name, currentHour, currentMinute, id])
  redirect('/timers/')
end

get('/user/showlogin/') do
  slim(:"user/login")
end

post('/login/') do
  username = params[:username]
  password = params[:password]

  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true
  result = db.execute("SELECT id, password_digest, permission FROM users WHERE username = ?", [username])

  if result.empty?
    set_error("Invalid login credentials")
    redirect("/user/showlogin/")
  end

  pwdigest = result.first["password_digest"]

  if BCrypt::Password.new(pwdigest) == password
    session[:user_id] = result.first["id"]
    session[:username] = username
    session[:permission] = result.first["permission"]
    redirect('/')
  else
    set_error("Invalid login credentials")
    redirect("/showlogin/")
  end
end

get('/user/showregister/') do
  slim(:"/user/register")
end

post('/register/') do 
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  permission = "user"

  db = SQLite3::Database.new('db/database.db')
  result = db.execute("SELECT id FROM users WHERE username=?", username)
    
  if result.empty?
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db.execute("INSERT INTO users (username, password_digest, permission) VALUES (?, ?, ?)", [username, password_digest, permission])
      redirect('/')
    else
      set_error("Password does not match")
      redirect('/user/showregister/')
    end
  else
    set_error("Account with username #{username} already exists.")
    redirect('/user/showregister/')
  end
end

post('/logout/') do
  session.clear
  session[:permission] = "guest"
  redirect("/")
end