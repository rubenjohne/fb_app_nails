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
  property  :blog_id,         Integer
  property  :blog,            String
  property  :blogger,         String
  property  :title,           String
  property  :description,     Text
  property  :blog_url,        String
  property  :filename,        String
  property  :url,             String
  property  :created_at,      DateTime
  property  :updated_at,      DateTime
  property  :size,            Integer
  property  :content_type,    String
  
end

DataMapper.finalize

DataMapper.auto_migrate!


# set utf-8 for outgoing
before do 
  headers "Content-Type" => "text/html; charset=utf-8"
end

get "/" do
  # will add  a function later to check if the user liked the page then redirect to unlocked or locked page
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
  @art.content_type = params[:image][:type]
  @art.size = File.size(params[:image][:tempfile])
  if @art.save
    path = File.join(Dir.pwd, "/public/arts", @art.filename)
    File.open(path, "wb") do |f|
      f.write(params[:image][:tempfile].read)
    end
    redirect "/show/#{@ad.id}"
  else
    redirect('/list')  
  end
end

get '/delete/:id' do
  
end

get '/show/:id' do
  @art = Art.get(params[:id])
  if @art
    erb :show
  else
    redirect('/list')
  end  
end

get '/votes/:id' do

end
