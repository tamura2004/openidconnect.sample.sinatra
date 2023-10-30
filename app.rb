require "sinatra"
require "sinatra/reloader"
require "net/http"
require "json"
require "logger"
require "base64"
require "securerandom"

CLIENT_ID = ENV["CLIENT_ID"]
CLIENT_SECRET = ENV["CLIENT_SECRET"]
REDIRECT_URI = ENV["REDIRECT_URI"]
AUTHORIZATION_ENDPOINT = ENV["AUTHORIZATION_ENDPOINT"]
TOKEN_ENDPOINT = ENV["TOKEN_ENDPOINT"]

STATE = SecureRandom::uuid
NONCE = SecureRandom::uuid

def log(title, obj)
  puts "-" * 40
  puts "#" + title
  puts JSON.pretty_generate(obj)
  puts "-" * 40
end

get "/" do
  request_params = {
    client_id: CLIENT_ID,
    response_type: "code",
    scope: "openid profile",
    redirect_uri: REDIRECT_URI,
    state: STATE,
    nonce: NONCE
  }
  log("authorization request", request_params)
  @link = "#{AUTHORIZATION_ENDPOINT}?#{URI.encode_www_form(request_params)}"
  erb :root
end

get "/callback" do
  log("authorization response", params)

  uri = URI.parse(TOKEN_ENDPOINT)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme === "https"

  request_params = {
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    grant_type: "authorization_code",
    code: params["code"],
    redirect_uri: REDIRECT_URI
  }

  log("token request", request_params)

  headers = {
    "Host" => "www.googleapis.com",
    "Content-Type" => "application/x-www-form-urlencoded"
  }

  response = http.post(uri.path, URI.encode_www_form(request_params), headers)
  response_params = JSON.parse(response.body)
  log("token response", response_params)

  @id_token = response_params["id_token"].split(/\./)[1].tr("-_","+/")
  @id_token += "=" * (@id_token.size % 4)
  @id_token = JSON.parse(Base64.decode64(@id_token))
  
  erb :id_token
end

