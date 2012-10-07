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

DataMapper.setup(:default, 'postgres://clldrlhbvlyhff:hEsSysSlr0J_2iAWaIS4tBElko@ec2-54-243-250-109.compute-1.amazonaws.com:5432/d40rbirnl0gui5')


get "/" do
  # will add  a function later to check if the user liked the page then redirect to unlocked or locked page
  erb :unlocked
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

