#!/usr/bin/env ruby
# scan.rb — YouTube group scrubber (Channels DVR)
# - Handles Windows-style paths coming from Channels
# - Logs verbosely with immediate flush
# - Uses HTTParty parsed_response + status checks
# - Builds .info.json path robustly
# - Optional DRY_RUN=true to test without PUT/POST

$stdout.sync = true
$stderr.sync = true

require 'httparty'
require 'json'
require 'date'
require 'uri'

# ---------- Config / Env ----------
server_host = ENV['SERVER_HOST']
video_root  = ENV['VIDEO_PATH']
dry_run     = (ENV['DRY_RUN'].to_s.downcase == 'true')

abort("Error: SERVER_HOST environment variable not set.") unless server_host
abort("Error: VIDEO_PATH environment variable not set.") unless video_root

SERVER_URL = "http://#{server_host}"
VIDEO_ROOT = video_root

# Labels/genres to match (case-insensitive)
LABEL_KEYS   = %w[Labels Genres].freeze
YOUTUBE_TAGS = [/youtube/i].freeze

# ---------- Helpers ----------
def log(msg)   = puts(msg)
def warnln(msg)= warn(msg)

def http_get_json(path)
  url = "#{SERVER_URL}#{path}"
  resp = HTTParty.get(url, timeout: 20)
  [resp.code, resp.parsed_response, resp.body]
rescue => e
  [0, nil, e.message]
end

def http_put_json(path, body_hash)
  url = "#{SERVER_URL}#{path}"
  HTTParty.put(
    url,
    body: body_hash.to_json,
    headers: { 'Content-Type' => 'application/json' },
    timeout: 20
  )
rescue => e
  Struct.new(:code, :body).new(0, e.message)
end

def http_post(path)
  url = "#{SERVER_URL}#{path}"
  HTTParty.post(url, timeout: 20)
rescue => e
  Struct.new(:code, :body).new(0, e.message)
end

# Normalize a Channels file['Path'] that may contain Windows separators/drive letters.
def normalize_relative_path(rel)
  s = rel.to_s

  # Convert backslashes to forward slashes
  s = s.tr('\\', '/')

  # Strip drive letters like C:/, D:/ at the start
  s = s.sub(/\A[A-Za-z]:\//, '')

  # Collapse duplicate slashes (but keep // in http(s) if ever present—unlikely here)
  s = s.gsub(%r{/+}, '/')

  # Remove any leading slash to keep it relative
  s.sub(/\A\//, '')
end

# Given a full path, swap the last extension with .info.json (or append if none)
def info_json_path_from(full_path)
  # Replace last ".ext" that doesn’t include a slash or backslash
  base = full_path.sub(/\.[^.\/\\]+$/, '')
  "#{base}.info.json"
end

# ---------- Start ----------
log "Starting scan at #{Time.now}  SERVER_URL=#{SERVER_URL}  VIDEO_PATH=#{VIDEO_ROOT}  DRY_RUN=#{dry_run}"

# Fetch groups
code, groups, raw = http_get_json('/dvr/groups/')
if code != 200 || !groups.is_a?(Array)
  warnln "GET /dvr/groups failed: code=#{code} sample=#{raw&.to_s&.slice(0,200)}"
  exit 1
end
log "Fetched #{groups.size} groups"

# Filter YouTube-labeled groups
youtube_groups = groups.select do |g|
  LABEL_KEYS.any? do |k|
    vals = g[k]
    vals.is_a?(Array) && vals.any? { |v| YOUTUBE_TAGS.any? { |r| v.to_s =~ r } }
  end
end
log "Matched #{youtube_groups.size} YouTube-labeled groups"

youtube_groups.each do |group|
  gid = group['ID']
  code, files, raw = http_get_json("/dvr/groups/#{gid}/files")
  unless code == 200 && files.is_a?(Array)
    warnln "GET /dvr/groups/#{gid}/files failed: code=#{code} sample=#{raw&.to_s&.slice(0,200)}"
    next
  end
  log "Group #{gid} has #{files.size} files"

  files.reverse_each do |file|
    rel = normalize_relative_path(file['Path'])
    full_path = File.join(VIDEO_ROOT, rel)

    log "\nScrubbing #{full_path}..."

    if file['CommercialsVerified']
      log "Already verified, skipping file."
      next
    end

    # Build .info.json path and verify presence
    info_path = info_json_path_from(full_path)

    # Debug checks
    dir = File.dirname(full_path)
    log "Dir exists? #{dir} -> #{Dir.exist?(dir)}"
    log "Video exists? #{full_path} -> #{File.exist?(full_path)}"
    log "Info JSON exists? #{info_path} -> #{File.exist?(info_path)}"

    unless File.exist?(info_path)
      log "No metadata file at #{info_path}, skipping."
      next
    end

    # Load metadata
    video_data = JSON.parse(File.read(info_path))
    title        = video_data['title']
    upload_date  = video_data['upload_date']
    thumbnail    = video_data['thumbnail']

    begin
      release_date = Date.parse(upload_date.to_s)
    rescue
      warnln "Bad upload_date=#{upload_date.inspect} for #{title.inspect}; skipping."
      next
    end

    package = {
      Thumbnail: thumbnail,
      Airing: {
        EpisodeTitle: title,
        OriginalDate: release_date
      }
    }

    if dry_run
      log "DRY_RUN: Would PUT /dvr/files/#{file['ID']} with Thumbnail + Airing"
      log "DRY_RUN: Would POST /dvr/files/#{file['ID']}/comskip/verify"
      next
    end

    put_resp = http_put_json("/dvr/files/#{file['ID']}", package)
    log "PUT /dvr/files/#{file['ID']} -> #{put_resp.code}"
    log "PUT body sample: #{put_resp.body.to_s.slice(0,200)}" if put_resp.code != 200

    post_resp = http_post("/dvr/files/#{file['ID']}/comskip/verify")
    log "#{post_resp.code} - scrubbed #{title}"
    log "POST body sample: #{post_resp.body.to_s.slice(0,200)}" if post_resp.code != 200
  end
end

log "\nScan completed at #{Time.now}"
