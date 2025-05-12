require 'sinatra'
require 'slim'
require './model'

enable :sessions

before do
  if session[:user_id] == nil
    session[:permission] = "guest"
  else
    result = get_user_credentials_from_id(session[:user_id], "db/database.db")
    session[:permission] = result.first["permission"]
  end
end

before("/default_timers/*") do
  if session[:permission] != "admin"
    set_error("Permission denied")
    redirect("/")
  end
end

before("/timers/*") do
  if session[:permission] == "guest"
    set_error("You must be logged in to view personal timers")
    redirect("/user/showlogin/")
  end
end

get('/') do
  custom_timers_result, default_timers_result = index_timers(session[:user_id], "db/database.db")

  slim(:home, locals:{custom_timers:custom_timers_result, default_timers:default_timers_result, user_id:session[:user_id], permission:session[:permission]})
end 

get('/default_timers/new/') do
  slim(:"default_timers/new")
end 
post('/default_timers/create/') do
  name = params[:name]
  hour = 0
  minute = params[:minute]

  create_default_timers(name, hour, minute, "db/database.db")

  redirect('/')
end
get('/default_timers/:time/edit/') do
  hour = params[:time].split("X")[0]
  minute = params[:time].split("X")[1]

  result = select_default_timers(hour, minute, "db/database.db")

  slim(:"/default_timers/edit", locals:{timer:result})
end 
post('/default_timers/:time/update/') do
  currentTime = split_params(params[:time])
  currentHour = currentTime[0]
  currentMinute = currentTime[1]

  name = params[:name]
  hour = params[:hour]
  minute = params[:minute]

  update_default_timers(hour, minute, name, currentHour, currentMinute, "db/database.db")

  redirect('/')
end
post('/default_timers/:time/delete/') do
  currentTime = split_params(params[:time])
  currentHour = currentTime[0]
  currentMinute = currentTime[1]

  delete_default_timers(currentHour, currentMinute, "db/database.db")
  redirect('/')
end 

get('/timers/') do
  user_id = session[:user_id]

  custom_timers_result = index_timers(user_id, "db/database.db")[0]

  slim(:"timers/index", locals:{custom_timers:custom_timers_result})
end
get('/timers/new/') do
  slim(:"timers/new")
end 
post('/timers/create/') do
  name = params[:name]
  hour = params[:hour]
  minute = params[:minute]
  user_id = session[:user_id]

  create_custom_timers(name, hour, minute, user_id, "db/database.db")

  redirect('/timers/')
end 
get('/timers/:time/edit/') do
  time = split_params(params[:time])
  hour = time[0]
  minute = time[1]
  user_id = session[:user_id]

  result = select_custom_timers(hour, minute, user_id, "db/database.db")

  slim(:"/timers/edit", locals:{timer:result})
end 
post('/timers/:time/update/') do
  currentTime = split_params(params[:time])
  currentHour = currentTime[0]
  currentMinute = currentTime[1]
  name = params[:name]
  hour = params[:hour]
  minute = params[:minute]
  user_id = session[:user_id]

  update_custom_timers(hour, minute, name, currentHour, currentMinute, user_id, "db/database.db")

  redirect('/timers/')
end
post('/timers/:time/delete/') do
  time = split_params(params[:time])
  hour = time[0]
  minute = time[1]
  user_id = session[:user_id]

  delete_custom_timers(hour, minute, user_id, "db/database.db")

  redirect('/timers/')
end

get('/user/showlogin/') do
  slim(:"user/login")
end
post('/login/') do
  session[:login_attempts] ||= []

  session[:login_attempts].append(Time.now())

  session[:login_attempts].reject! do |attempt|
    (Time.now - attempt) > 10
  end

  if session[:login_attempts].length > 4
    set_error("Too many login attempts, please wait a few seconds.")
    redirect("/user/showlogin/")
  else
    username = params[:username]
    password = params[:password]

    result = get_user_credentials(username, "db/database.db")

    if result.empty?
      set_error("Invalid login credentials")
      redirect("/user/showlogin/")
    end

    if password_matches?(result, password)
      session[:user_id] = result.first["id"]
      session[:username] = username
      session[:permission] = result.first["permission"]
      redirect('/')
    else
      set_error("Invalid login credentials")
      redirect("/user/showlogin/")
    end
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

  result = username_available?(username)
    
  if result
    if (password == password_confirm)
      register_user(username, password, permission)
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