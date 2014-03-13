require 'logger'
require 'restclient'
require 'time'

PROJECT_ID = ENV["PIVOTAL_TRACKER_PROJECT_ID"] || nil
TOKEN = ENV["PIVOTAL_TRACKER_API_TOKEN"] || nil
STORY_PREFIX = ENV["PIVOTAL_TRACKER_STORY_PREFIX"] || nil


log = Logger.new(STDOUT)
log.level = Integer(ENV["TAGGER_LOG_LEVEL"] || Logger::INFO)

raise "You must set the PIVOTAL_TRACKER_API_TOKEN env variable or define it in the script" unless TOKEN
raise "You must set the PIVOTAL_TRACKER_PROJECT_ID env variable or define it in the script" unless PROJECT_ID
raise "You must set the PIVOTAL_TRACKER_STORY_PREFIX env variable or define it in the script" unless PROJECT_ID

project_api = RestClient::Resource.new("https://www.pivotaltracker.com/services/v5/projects/#{PROJECT_ID}",
                                            headers: {"X-TrackerToken" => TOKEN})

# Bump the number of pages fetched if you run over 1000 stories.
pages = 2
results_per_page = 500

stories = []

pages.times do |page_index|
  marshalled_stories = project_api["stories?limit=#{results_per_page}&offset=#{(results_per_page * page_index)}"].get
  stories.concat(JSON.parse(marshalled_stories))
end

sorted_stories = stories.sort_by {|s| [s["id"], DateTime.iso8601(s["created_at"])]}

newly_tagged_story_count = 0
max_seen_story_id = 0

sorted_stories.each do |s|
  pivotal_id = s["id"]
  story_name = s["name"]
  stringy_story_id = story_name[/\A#{Regexp.quote(STORY_PREFIX)}(\d+)/, 1]
  if stringy_story_id
    story_id = Integer(stringy_story_id)
    max_seen_story_id = max_seen_story_id < story_id ? story_id : max_seen_story_id
    log.debug "Skipping story with existing ID: #{story_name}"
    next
  end

  newly_tagged_story_count += 1
  max_seen_story_id += 1

  new_story_name = "#{STORY_PREFIX}#{max_seen_story_id} - #{story_name}"
  log.info "Adding new ID to story: #{new_story_name}"

  # PUT the new name back into Pivotal.
  project_api["stories/#{pivotal_id}"].put(({name: new_story_name}.to_json), {content_type: :json})
end

log.info "Tagged #{newly_tagged_story_count} new stories out of #{sorted_stories.length} total."
