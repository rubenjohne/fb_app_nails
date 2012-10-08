require "sinatra"
require 'koala'
require "pg"

require "data_mapper"

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

DataMapper.auto_update!


# set utf-8 for outgoing
before do 
  headers "Content-Type" => "text/html; charset=utf-8"
end

get "/" do
  # will add  a function later to check if the user liked the page then redirect to unlocked or locked page
  @title = "vote for Nail Art"
  @arts = Art.all(:order => [:created_at.desc])
  erb :unlocked
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end


get '/art' do

end

get '/list' do
  @title = "List Arts"
  @arts = Art.all(:order => [:created_at.desc])
  erb :list
end

get '/new' do
  @title = "Create a new Nail Art"
  erb :new
end

post '/create' do
  @art = Art.new(params[:art])
  if @art.save
    redirect "/show/#{@art.id}"
  else
    redirect('/list')  
  end
end

get '/delete/:id' do
  art = Art.get(params[:id])
  unless art.nil?
    art.destroy
  end
  redirect('/list')
end

get '/show/:id' do
  @art = Art.get(params[:id])
  if @art
    erb :show
  else
    redirect('/list')
  end  
end

get '/vote/:id' do
  art = Art.get(params[:id])
  art.votes.create(:ip_address => env["REMOTE_ADDR"], :voted_by => "Ruben")
end