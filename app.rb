require "sinatra"
require 'koala'
require "pg"

require "data_mapper"

require "./lib/authorization"

require "date"

enable :sessions
set :raise_errors, true
set :show_exceptions, true

# Scope defines what permissions that we are asking the user to grant.
# In this example, we are asking for the ability to publish stories
# about using the app, access to what the user likes, and to be able
# to use their pictures.  You should rewrite this scope with whatever
# permissions your app needs.
# See https://developers.facebook.com/docs/reference/api/permissions/
# for a full list of permissions
# FACEBOOK_SCOPE = 'user_likes,user_photos,user_photo_video_tags'
FACEBOOK_SCOPE = ''

unless ENV["FACEBOOK_APP_ID"] && ENV["FACEBOOK_SECRET"]
  abort("missing env vars: please set FACEBOOK_APP_ID and FACEBOOK_SECRET with your app credentials")
end

# database connection from heroku
DataMapper.setup(:default, ENV["DATABASE_URL"])

class Art
  
  include DataMapper::Resource
  
  property  :id,              Serial
  property  :blog_id,         Integer,  :required => false
  property  :blog,            String,  :required => false
  property  :blogger,         String,  :required => false
  property  :title,           String,  :required => false
  property  :description,     Text,  :required => false
  property  :blog_url,        String,  :required => false
  property  :filename,        String,  :required => false
  property  :url,             String,  :required => false
  property  :created_at,      DateTime,  :required => false
  property  :updated_at,      DateTime,  :required => false
  property  :size,            Integer,  :required => false
  property  :content_type,    String,  :required => false
  
  has n, :votes
end

class Vote
  
  include DataMapper::Resource
  
  property :id,               Serial
  property :voted_by,         String, :required => false
  property :ip_address,       String  
  property :created_at,       DateTime 
  
  belongs_to :art
  
end

DataMapper.finalize

# Create or upgrade the database all at once
DataMapper.auto_upgrade!

helpers do
  include Sinatra::Authorization 
  
  def authenticator 
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
  end
end

# set utf-8 for outgoing
before do 
  headers "Content-Type" => "text/html; charset=utf-8"
end

configure do
  set :user_name, "dummy"
end

post "/" do
  signed_request = params[:signed_request]
  oauth = Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"])
  @signed_request = oauth.parse_signed_request(signed_request)
  #@graph = Koala::Facebook::API.new
  #@user = @graph.get_object(@signed_request["user_id"])  
  #unless @user.nil? 
  #  set :user_name, @user['username'] 
  #end
  liked_page = @signed_request['page']['liked'] ||= nil
  if liked_page
    # this is the login information once they liked the page 
    @graph = Koala::Facebook::API.new(session[:access_token])
  
    # check if the user is actually logged in to be able to vote
    if session[:access_token]
      @user = @graph.get_objects("me")  
      set :user_name, @user['me']['username']
      @arts = Art.all(:order => [:blog_id.asc])
      erb :unlocked
    else 
      redirect "/auth/facebook"  
    end
  else
    erb :locked 
  end  
end

get "/" do
  
  request.env.map { |e| e.to_s + "\n" }
  
  @graph = Koala::Facebook::API.new(session[:access_token])

  # check if the user is actually logged in to be able to vote
  if session[:access_token]
    @user = @graph.get_objects("me")  
    set :user_name, @user['me']['username']
    @arts = Art.all(:order => [:blog_id.asc])
    erb :unlocked
  else 
    redirect "/auth/facebook"  
  end
end

get '/list' do
  require_admin
  @title = "List Arts"
  @arts = Art.all(:order => [:blog_id.asc])
  erb :list
end

get '/new' do
  require_admin
  @title = "Create a new Nail Art"
  erb :new
end

post '/create' do
  require_admin
  @art = Art.new(params[:art])
  if @art.save
    redirect "/show/#{@art.id}"
  else
    redirect('/list')  
  end
end

get '/edit/:id' do
  require_admin
  @art = Art.get(params[:id])
  if @art
    erb :edit
  else
    redirect('/list')
  end  
end

post '/update' do
  require_admin
  @art = Art.get(params[:id])
  if @art.update(params[:art])
    redirect "/show/#{@art.id}"
  else 
    redirect('/list')
  end  
end

get '/delete/:id' do
  require_admin
  art = Art.get(params[:id])
  unless art.nil?
    art.destroy
  end
  redirect('/list')
end

get '/show/:id' do
  require_admin
  @art = Art.get(params[:id])
  if @art
    erb :show
  else
    redirect('/list')
  end  
end

get '/vote/:id' do
  @art = Art.get(params[:id])
  erb :vote
end

post '/vote' do
  art = Art.get(params[:id])
  # check if the user voted already
  vote = Vote.last(:voted_by => settings.user_name)
  unless vote.nil? 
     diff = Time.now.day - vote.created_at.to_time.day 
     if diff != 0 
       art.votes.create(:ip_address => env["REMOTE_ADDR"], :voted_by => settings.user_name)
       erb :voted  
     else
       erb :novote
     end    
   else
     art.votes.create(:ip_address => env["REMOTE_ADDR"], :voted_by => settings.user_name)
     erb :voted      
   end
end

get '/official-rules' do
  erb :official_rules
end

get '/auth/facebook' do
  session[:access_token] = nil
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
  session[:access_token] = authenticator.get_access_token(params[:code])
  redirect '/'
end