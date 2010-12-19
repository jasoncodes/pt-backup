require 'rubygems'
require 'bundler'
Bundler.require

require 'fileutils'

@config = YAML::load_file('config.yml')
raise "api_token missing from config.yml" if @config['api_token'].nil? || @config['api_token'].empty?
PivotalTracker::Client.token = @config['api_token']

def tracker_get(url, path, max_redirects = 5)
  uri = URI.parse url
  http = Net::HTTP.new uri.host, uri.port
  http.use_ssl = uri.is_a?(URI::HTTPS)
  http.request_get uri.request_uri, { 'X-TrackerToken' => @config['api_token'] } do |response|
    case response
    when Net::HTTPSuccess
      File.open "#{path}.new", 'w' do |io|
        response.read_body do |segment|
          io.write segment
        end
      end
      FileUtils.mv "#{path}.new", path
    when Net::HTTPRedirection
      raise ArgumentError, 'HTTP redirect too deep' if max_redirects < 1
      tracker_get url, response['location'], max_redirects - 1
    else
      response.error!
    end
  end
end

PivotalTracker::Project.all.each do |project|
  
  puts "Backing up #{project.name.inspect}..."
  FileUtils.mkdir_p "projects/#{project.name}"
  
  tracker_get \
    "https://www.pivotaltracker.com/services/v3/projects/#{project.id}/stories",
    "projects/#{project.name}/stories.xml"
  
end
