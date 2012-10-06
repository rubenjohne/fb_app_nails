require "sinatra"
require 'koala'

require "pg"
require "dm-core"
require "dm-timestamps"
require "dm-migrations"

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

configure do 
  # Use Heroku database
  DataMapper.setup(:default, ENV['DATABASE_URL'])
end


class Art 
  
  include DataMapper::Resource
  
  
  property :id,             Serial
  property :blogger,        Integer
  property :title,          String
  property :description,    String
  property :name,           String
  property :blog_name,      String
  property :blog_url,       String
  property :filename,       String
  property :url,            String
  property :created_at,     DateTime
  property :updated_at,     DateTime
  property :size,           Integer
  property :content_type,   String
  
  def handle_upload(file)
    self.content_type = file[:type]
    self.size = File.size(file[:tempfile])
    path = File.join(Dir.pwd, "/public/arts", self.filename)
    File.open(path, "wb") do |f|
      f.write(file[:tempfile].read)
    end
  end
  
end

#Create or upgrade all tables at once
DataMapper.auto_upgrade!



get "/" do
  # will add  a function later to check if the user liked the page then redirect to unlocked or locked page
  erb :unlocked
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

