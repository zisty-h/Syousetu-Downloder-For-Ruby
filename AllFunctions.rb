require 'sinatra'
require 'nokogiri'
require 'net/http'
require 'json'
require 'google/apis/drive_v3'
require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'selenium-webdriver'
require 'yaml'
#require './class/twitter.rb'
#
help = ""
File.open(path="./data/search_data", mode="r") do |file|
  file.each do |text|
    help += text
  end
end

tokens_str = ""
File.open(path="./data/Tokens.json", mode="r") do |file|
  file.each do |t|
    tokens_str += t
  end
end

Tokens = JSON.parse tokens_str
# DriveAPI setting
OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'School PC Service'.freeze
CREDENTIALS_PATH = 'credentials.json'.freeze
TOKEN_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE

client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
user_id = 'default'
credentials = authorizer.get_credentials(user_id)

if credentials.nil?
  url = authorizer.get_authorization_url(base_url: OOB_URI)
  puts 'Open the following URL in the browser and enter the ' \
         "resulting code after authorization:\n" + url
  code = gets
  credentials = authorizer.get_and_store_credentials_from_code(
    user_id: user_id, code: code, base_url: OOB_URI
  )
end

drive_service = Google::Apis::DriveV3::DriveService.new
drive_service.client_options.application_name = APPLICATION_NAME
drive_service.authorization = credentials

youtube_service = Google::Apis::YoutubeV3::YouTubeService.new
youtube_service.key = Tokens["YouTube"]["Token"]

$folder_id = "1anMg_s1OQtEjgiSp8MGOpGCNOaIaQ3WV"
puts "FolderID: #{$folder_id}"

Book_base_url = "https://ncode.syosetu.com/"
Api_base_url = "https://api.syosetu.com/novelapi/api?out=json"

def decode text
  text.unpack("U*").map{ |char| [char].pack('U') }.join
end

def upload title, file, drive_service, mode, type='text/plain'
  if type == 'text/plain'
    file_metadata = {
      name: "#{title}.#{mode}",
      mime_type: type,
      parents: [$folder_id]
    }
  else
    file_metadata = {
      name: "#{title}.#{mode}",
      mime_type: type,
      parents: ["1QiUq2Yi5Xcm5l2apsIUP__tINrN-NwPx"]
    }
  end

  drive_service.create_file(file_metadata, upload_source: file, fields: 'id')
end

get "/" do
  "Hello world!"
end

get "/book" do
  book_id = params[:ncode]
  puts "Book id is #{book_id}"
  api_url = "#{Api_base_url}&ncode=#{book_id}"
  book_url = "#{Book_base_url}#{book_id}/"
  puts "URL: #{api_url}"
  response = JSON.parse Net::HTTP.get_response(URI.parse(api_url)).body
  book_data = response[1]
  # puts book_data
  book_title = decode text=book_data["title"]
  all_books = book_data["general_all_no"]
  puts "Book title: #{book_title}"
  puts "General all no: #{all_books.to_s}"
  puts "Start download."
  book_text = ""
  (1..all_books).each do |no|
    url = "#{book_url}#{no.to_s}/"
    puts "url: #{url}. #{no.to_s}/#{all_books.to_s}"
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == "https")
    request = Net::HTTP::Get.new(url)
    request.add_field('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36')
    response = http.request(request)

    html = Nokogiri.parse response.body
    data = html.css('#novel_honbun')[0]
    puts "Class: #{data.class}"
    book_text = "#{book_text}\n#{data.content}"
  end
  file = "./novels/#{book_title}.txt"
  File.open(path=file, mode="w") do |file|
    file.write(book_text)
  end
  upload title=book_title, file=file, drive_service=drive_service, mode="txt"
  send_file file
end

get "/search" do
  search_no = params[:q]
  url = URI.parse("https://api.syosetu.com/novelapi/api/?genre=#{search_no.to_s}&out=json")
  response = JSON.parse Net::HTTP.get_response(url).body
  response.delete_at 0
  puts response
  response_data = {}
  response.each do |json|
    response_data[json["title"]] = {
      "ncode" => json["ncode"],
      "story" => json["story"],
      "general_all_no" => json["general_all_no"]
    }
  end
  response_data.to_yaml.to_s
end

get "/search_help" do
  help
end

get "/book/create" do
  title = params[:title]
  book_metadata = {
    name: "#{title}.txt",
    mime_type: 'application/vnd.google-apps.document',
    parents: ["18LwWejCQgMHGCSVpUoCn02n7kBVybwlz"]
  }
  file = drive_service.create_file(book_metadata, fields: 'id')
  file.id
end

get "/book/post" do
  file_id = params[:id]
  file_name = drive_service.get_file(file_id).name
  book = drive_service.export_file(file_id, 'text/plain')
  File.open(path="./PostBook/#{file_name}.txt", mode="w") do |file|
    file.write book
  end
  return "Done"
end

get "/youtube/get" do
  video_url = params[:url]
  system("./YouTube/dist/ytdl-python.exe #{video_url}")
  file = Dir.glob("./*.mp4")
  puts file[0]
  title = File.basename(file[0], ".mp4")
  upload title=title, file=file[0], drive_service=drive_service, mode="mp4", type="video/mp4"
  File.delete(path=file)
  "Done"
end

get "/youtube/search" do
  query = params[:q]
  res = youtube_service.list_searches("id,snippet", type:'video', q:query, max_results: 50).to_h

  items = res[:items]
  puts items
  response = ''
  items.each do |item|
    title = item[:snippet][:title]
    video_url = "https://www.youtube.com/watch?v=#{item[:id][:video_id]}"
    puts "Title: #{title}\nVideo_url: #{video_url}"
    response += "<div><h1>Title: #{title}</h1><br>\n<h2>Video_url: #{video_url}</h2><br><br></div>\n\n"
  end
  puts "Response"
  File.open(path="./res.html", mode="w") do |file|
    file.write response
  end
  send_file "./res.html"
end