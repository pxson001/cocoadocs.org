#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'cocoapods'
gem 'nap'
require 'rest'

require_relative 'classes/_utils.rb'

ENV['HOST_URL'] ||= 'http://192.168.99.100:4567/'

ENV['TRUNK_NOTIFICATION_PATH'] ||= 'jmango360'
# ENV["COCOADOCS_API"] ||= 'http://localhost:6666'
# ENV['COCOADOCS_TOKEN'] ||= '1234'

trunk_notification_path = ENV['TRUNK_NOTIFICATION_PATH']
trunk_notification_path ||= ARGV[0]
abort "You need to give a Trunk webhook URL" unless trunk_notification_path

# auth_token = ENV['COCOADOCS_TOKEN']
# abort "You need to give a Trunk webhook URL" unless auth_token

set :pod_count, 0
set :bind, '0.0.0.0'
set :port, 5555

post "/hooks/trunk/" + trunk_notification_path do
  data = JSON.parse(request.body.read)
  puts "Got a webhook notification: " + data["type"] + " - " + data["action"]

  process_url data["data_url"]
  "{ success: true }"
end

get "/error/:pod/:version" do
  content_type :json
  # get error info for a pod
   error_json_path = "errors/#{params[:pod]}/#{params[:version]}/error.json"
   error_message_for_path error_json_path
end

get "/error/:pod" do
  content_type :json

  # get generic error info for a pod
   error_json_folder = "errors/#{params[:pod]}/"
   if File.directory? error_json_folder
     # return first found
     error_json_path = Dir[error_json_folder + "/*/*.json"].first
     error_message_for_path error_json_path
   end

   error_message_for_path "random_path"
end

get "/redeploy/:pod/latest" do
  content_type :json
  begin
    trunk_spec = REST.get(escape_url(ENV['HOST_URL'] + "api/v1/pods/" + params[:pod])).body
    versions = JSON.parse(trunk_spec)["versions"]
    versions = versions.map { |s| Pod::Version.new(s["name"]) }.sort.map { |semver| semver.version }
    trunk_spec_latest = REST.get(escape_url(ENV['HOST_URL'] + "api/v1/pods/" + params[:pod]) + "/versions/" + versions[-1]).body
    
    process_url JSON.parse(trunk_spec_latest)["data_url"]

    # process_url "https://gitlab.com/api/v3/projects/2133476/repository/blobs/master?filepath=Specs/#{ params[:pod] }/#{ versions[-1] }/#{ params[:pod] }.podspec.json"
    return { :parsing => true }.to_json

  rescue Exception => e
    p e.message
    return { :parsing => false, :error => e.message }.to_json
  end
end

get "/redeploy/:pod/:version" do
    content_type :json

    trunk_spec = REST.get(escape_url(ENV['HOST_URL'] + "api/v1/pods/" + params[:pod]) + "/versions/" + params[:version]).body

    process_url JSON.parse(trunk_spec)["data_url"]

   return { :parsing => true }.to_json
end

get "/recent_pods_count" do
  old_recent_pods = settings.pod_count
  set :pod_count, 0
  return old_recent_pods.to_s
end

get "/" do
  content_type :text
  "Hi"
end

private

def error_message_for_path path
  if File.exists? path
    return "report_error(" + File.read(path) + ")"
  end
  '{"message":"Could not find any errors, perhaps CocoaDocs has not ran the processing?", "trace" :[]}'
end

def process_url url
  set :pod_count, settings.pod_count + 1
  this_folder = File.expand_path(File.dirname(__FILE__))
  pid = Process.spawn(File.join(this_folder, "./cocoadocs.rb"), "cocoadocs", "url", escape_url(url), { :chdir => this_folder })
  Process.detach pid
end
