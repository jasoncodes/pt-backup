require 'rubygems'
require 'bundler'
Bundler.require

require 'fileutils'
require 'yaml'

@config = YAML::load_file('config.yml')
raise "api_token missing from config.yml" if @config['api_token'].nil? || @config['api_token'].empty?
client = TrackerApi::Client.new(token: @config['api_token'])

def tracker_get(url, path, max_redirects = 5)
  rows = []
  offset = 0

  begin
    response = HTTP.get(url, headers: {'X-TrackerToken' => @config['api_token']}, params: {offset: offset})
    this_rows = response.parse
    raise if this_rows.empty?
    rows += this_rows
    offset += this_rows.size

    rows_total = Integer(response['x-tracker-pagination-total'])
  end until rows.size >= rows_total

  File.write "#{path}.new", JSON.pretty_generate(rows)
  FileUtils.mv "#{path}.new", path
end

client.projects.each do |project|
  
  puts "Backing up #{project.name.inspect}..."
  FileUtils.mkdir_p "projects/#{project.name}"
  
  tracker_get \
    "https://www.pivotaltracker.com/services/v5/projects/#{project.id}/stories",
    "projects/#{project.name}/stories.json"
  
end
