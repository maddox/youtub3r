require 'httparty'
require 'json'

if !ENV['SERVER_HOST']
  puts "Error: SERVER_HOST environment variable not set."
  exit
end

if !ENV['VIDEO_PATH']
  puts "Error: VIDEO_PATH environment variable not set."
  exit
end

if !ENV['VIDEO_GROUPS']
  puts "Error: VIDEO_GROUPS environment variable not set."
  exit
end


VIDEO_GROUPS = ENV['VIDEO_GROUPS'].split(',')
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

VIDEO_GROUPS.each do |group_id|
  source_files = HTTParty.get("#{SERVER_URL}/dvr/groups/#{group_id}/files")

  source_files.reverse.each do |file|
    full_path = "#{VIDEO_PATH}/#{file['Path']}"

    puts
    puts "scrubbing #{full_path}."

    if file['CommercialsVerified']
      puts "Already verified, skipping file."
      next
    end

    video_data_path = full_path.gsub(File.extname(full_path), '.info.json')
    next unless File.exists?(video_data_path)

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

