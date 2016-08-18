require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def get_db
  db = SQLite3::Database.new 'data.db'
  db.results_as_hash = true
  return db
end


configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Feel free to <a href="/appoint">make an appointment</a>?'
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  if params['username'] == 'admin' && params['passwd'] == 'mypass'
    session[:identity] = params['username']
    where_user_came_from = session[:previous_url] || '/'
    redirect to where_user_came_from
  else
    @error = 'Wrong login/password pair'
    halt erb(:login_form)
  end
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
    # erb 'This is a secret place that only <%=session[:identity]%> has access to!'

#  @usresults = dbread.execute 'select * from data order by id desc'
  db = get_db
  @app_hash = db.execute 'select * from data order by id desc'
  @barb_hash = db.execute 'select * from barbers order by id'
  @sample = "Sample"
  erb :secret_area
end

get '/about' do
  erb :about
end

get '/contactus' do
  erb :contacts
end

post '/contactus' do
  @email = params[:email]
  @msgtext = params[:message]

  msgdb = get_db
  msgdb.execute( "INSERT INTO contact ( email, message ) VALUES ( ?, ? )", [@email, @msgtext])
  

  @title = "Thank you"
  @message = "Your message to us has been sent"
  erb :message
end

get '/appoint' do
  db = get_db
  @barba_hash = db.execute 'select * from barbers order by id'
  erb :appoint
end

post '/appoint' do
  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @barber = params[:barber]
  @color = params[:colorpicker]
  err_h = {
    :username => 'Please enter username',
    :phone => 'Please enter phone number',
    :datetime => 'Please select date and time',
      }
  # err_h.each do |key, value| 
  #     if params[key] == ''
  #       @error = err_h[key]
  #       return erb :appoint
  #     end
  # end
  # @error = err_h.select {|k,v| params[k] == ''}.values.join(', ')
  # if @error != ''
  #   return erb :appoint
  # end
  @title = "Thank you, #{@username}"
  @message = "We'll be waiting for you at #{@datetime}"

  dba = get_db  
  dba.execute( "INSERT INTO data ( name, phone, datetime, barber, color ) VALUES ( ?, ?, ?, ?, ? )", [@username, @phone, @datetime, @barber, @color])

  erb :message
end

post '/barberadd' do
  @barbername = params[:barbername]
  @optname = params[:optname]
  dbb = get_db
  dbb.execute( "INSERT INTO barbers (barber, optname) VALUES ( ?, ?)", [@barbername, @optname])
  @title = "Complete"
  @message = "Barber #{@barbername} with inner name #{@optname} has beed added " + session[:previous_url]
  erb :message
end