require "sinatra"
require 'koala'
require 'base64'
require 'crack/json'


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


helpers do
  def base64_url_decode str
    encoded_str = str.gsub('-','+').gsub('_','/')
    encoded_str += '=' while !(encoded_str.size % 4).zero?
    Base64.decode64(encoded_str)
  end

  def decode_data(signed_request)
    encoded_sig, payload = signed_request.split('.')
    data = base64_url_decode(payload)
  end
end


get "/" do

  @encoded_request = params[:signed_request]
  @json_request = decode_data(@encoded_request)
  @signed_request = Crack::JSON.parse(@json_request)
  if @signed_request['page']['liked']
    erb :unlocked
  else
    erb :locked
  end
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

