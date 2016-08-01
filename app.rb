require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'

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
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
  erb :secret_area
end

get '/about' do
  erb :about
end

get '/contacts' do
  erb :contacts
end

post '/contacts' do
  @email = params[:email]
  @msgtext = params[:message]
  f = File.open("./public/smessages.txt","a")
  f.write  "User: #{@email}, message: #{@msgtext}\n"
  f.close
  @title = "Thank you"
  @message = "Your message to us has been sent"
  erb :message
end

get '/appoint' do
  erb :appoint
end

post '/appoint' do
  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @barber = params[:barber]
  @title = "Thank you, #{@username}"
  @message = "We'll be waiting for you at #{@datetime}"
  
  f = File.open("./public/susers.txt","a")
  f.write  "User: #{@username}, phone: #{@phone}, barber: #{@barber}, date: #{@datetime}\n"
  f.close
  erb :message
end