require 'httparty'
require 'json'
require 'date'

if !ENV['SERVER_HOST']
  puts "Error: SERVER_HOST environment variable not set."
  exit
end

if !ENV['VIDEO_PATH']
  puts "Error: VIDEO_PATH environment variable not set."
  exit
end

SERVER_URL = "http://#{ENV['SERVER_HOST']}"
VIDEO_PATH = ENV['VIDEO_PATH']

class Video
  attr_accessor :title, :summary, :trailer_url, :release_date, :thumbnail_url

  def initialize(video_data)
    @title = video_data['title']
    @release_date = Date.parse(video_data["upload_date"])
    @thumbnail_url = video_data['thumbnail']
  end
end

def normalize_relative_path(rel)
  rel.to_s.tr('\\', '/').sub(/\A[A-Za-z]:\//, '') # replace \ with / and drop drive letters
end

groups = HTTParty.get("#{SERVER_URL}/dvr/groups/").parsed_response
youtube_groups = groups.select { |g| (g['Labels'] && g['Labels'].include?('youtube')) || (g['Genres'] && g['Genres'].include?('YouTube')) }

youtube_groups.each do |group|
  source_files = HTTParty.get("#{SERVER_URL}/dvr/groups/#{group['ID']}/files").parsed_response

  source_files.reverse.each do |file|
    relative = normalize_relative_path(file['Path'])
    full_path = File.join(VIDEO_PATH, relative)

    puts
    puts "Scrubbing #{full_path}."

    if file['CommercialsVerified']
      puts "Already verified, skipping file."
      next
    end

    video_data_path = full_path.sub(/\.[^.\/\\]+$/, '.info.json')
    unless File.exist?(video_data_path)
      puts "No metadata file at #{video_data_path}, skipping."
      next
    end

    video_data = JSON.parse(File.open(video_data_path).read)
    video = Video.new(video_data)
    
    package = { Thumbnail: video.thumbnail_url,
                Airing: { EpisodeTitle: video.title, 
                          OriginalDate: video.release_date, 
                        }
              }

    res = HTTParty.put("#{SERVER_URL}/dvr/files/#{file['ID']}", :body => package.to_json)
    res = HTTParty.post("#{SERVER_URL}/dvr/files/#{file['ID']}/comskip/verify")

    puts "#{res.code} - scrubbed #{video.title}"
  end
end
