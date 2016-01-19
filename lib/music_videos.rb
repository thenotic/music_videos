require 'open-uri'
require 'json'
require 'nokogiri'
require 'typhoeus'
require 'rmagick'

module MusicVideos
class Find

def initialize(lastfm_api_key, youtube_api_key)
@lastfm_api_key  = lastfm_api_key
@youtube_api_key = youtube_api_key
end

def get_artist_songs(lastfm_name)
tracks = []
for i in (0..5)
url = "http://ws.audioscrobbler.com/2.0/?api_key=#{@lastfm_api_key}&format=json&artist=#{lastfm_name}&method=artist.getTopTracks&limit=100&page=#{i}"
tracks << JSON.parse(open(url).read)['toptracks']['track'].map{|x| x['name']} rescue next
end
return tracks
end


def artist_search(artist_name)
url = "http://ws.audioscrobbler.com/2.0/?api_key=#{@lastfm_api_key}&format=json&artist=#{URI.encode(artist_name)}&method=artist.search"
lastfm_name = JSON.parse(open(url).read)['results']['artistmatches']['artist'][0]['url'].gsub("http://www.last.fm/music/","")
return lastfm_name
end

def get_clean_tracks(tracks)
tracks_clean = tracks.flatten.uniq.reject{|x| x.to_s.downcase.gsub(/\([^()]*\)/,"").scan(/feat|ft|\)|prod| \- |\||\]|dir/).count > 0 rescue next}.map{|x| x.downcase.gsub("in'","ing").gsub(/\([^()]*\)/,"")}.uniq
tt = []
tracks_clean.compact.each do |x| 
if x[0].match(/[0-9]/)
tt << x.gsub(/^[0-9]*/,'')[1..-1].join(" ").gsub(".","").strip rescue next
else
tt << x
end
end
return tt
end

def get_youtube_links(artist,tt)
l = artist
i = 1
yy = []
checkyy = []
hydra = Typhoeus::Hydra.new
tt.compact.each do |x|
i = i+1;puts i
artist = l
title = x
artist.gsub!('&',' and ')
title.gsub!('&',' and ')
search ="#{URI.encode(artist.gsub(/\(.*?\)/, ''))}%20#{URI.encode(title.gsub(/\(.*?\)/, ''))}"
url = "https://www.googleapis.com/youtube/v3/search?q=#{search}&key=#{@youtube_api_key}&part=snippet&type=video" #api key as 2nd gmail
request = Typhoeus::Request.new(url, followlocation: false)
request.on_complete do |response|
page = JSON.parse(Nokogiri::HTML(response.body)) rescue next
first_link = page['items'][0]['id']['videoId'] rescue next
y_title = page['items'][0]['snippet']['title'] rescue next
x_title = "#{x} #{l}"
confidence = x_title.downcase ^ y_title.downcase
confidence2 = ccc(artist,title,y_title)
if confidence > 0.6 || (confidence2 > 0.65)
unless y_title.downcase.match(/lyric|review|cover/)
yy << [x, first_link, y_title, title, confidence]
end
end
end
hydra.queue(request)
end
hydra.run

return yy

end


def ccc(artist,title,y_title)
total_title = "#{artist.gsub(/\(.*?\)/, '').downcase} #{title.downcase}".split(' ')
y_title_real = y_title.downcase.split(' ')
score = (1.to_f - (total_title - y_title_real).count.to_f / total_title.count.to_f)
return score
end


def get_previews(yy)
yy = yy.uniq{|x| x[1]}
k = []
hydra = Typhoeus::Hydra.new(max_concurrency: 20)
yy.each do |x|
url = "http://www.genyoutube.com/preview.php?id=#{x[1]}"
request = Typhoeus::Request.new(url, followlocation: false, )
request.on_complete do |response|
page = Nokogiri::HTML(response.body) rescue next
image_url = page.css('img').select{|x| x.attr('src').to_s.include?('/M1')}[0].attr('src').to_s rescue page.css('img')[0].attr('src').to_s rescue next
k  << [x[0], x[1].gsub('watch.php?v=',''), image_url]
end
hydra.queue(request)
end
hydra.run

return k
end

def vid3(image_url)

image = Magick::ImageList.new  
urlimage = open(image_url) # Image Remote URL 
image.from_blob(urlimage.read)

width  = image.columns/5
height = image.rows/5
images = []
0.upto(5-1) do |x|
0.upto(5-1) do |y|
images << image.crop( Magick::NorthWestGravity, x*width, y*height, width, height, true)
end
end

diff = images[10].difference(images[11])

return diff[1]

end


def get_videos(artist, k)
videos = []
i = 0
k.each do |x|
i = i+1;puts i
size = vid3(x[2]).to_f 
if size > 0.01
videos << [x[0], size, x[1]]
end
end
video_output = []; i = 0
videos.each do |x|
bb = Object.new
bb.class.module_eval { attr_accessor :artist, :title, :youtube_url}
bb.artist =  artist
bb.title = x.flatten[0]
bb.youtube_url = x.flatten[2]
video_output << bb 
end
return video_output
end




def find_artist_music_videos(artist)
lastfm_name = artist_search(artist)
tracks = get_artist_songs(lastfm_name)
clean_tracks = get_clean_tracks(tracks)
youtube_links = get_youtube_links(artist, clean_tracks)
previews =  get_previews(youtube_links)
videos = get_videos(artist, previews)

return videos
end


end


end

class String

def clean_name
return self.gsub(/\(.*?\)/, '').strip
end


  # Jaro-Winkler distance
  # @param [String] other string
  # @return [Float] distance, normalized between 0.0 (no match) and 1.0 (perfect match)
  def ^(other)
    return 1.0 if self == other
    return 0.0 if self.empty? or other.empty?

    s1 = self.codepoints.to_a
    s2 = other.codepoints.to_a
    s1, s2 = s2, s1 if s1.size > s2.size
    s1s, s2s = s1.size, s2.size
    m, t = 0.0, 0 
    max_dist = s2s/2 - 1

    m1 = Array.new(s1s, -1)
    m2 = Array.new(s2s, false)

    # find m
    s1.each_with_index do |a, ia|
      lower = ia > max_dist ? ia-max_dist : 0
      upper = ia+max_dist < s2s ? ia+max_dist : s2s
      s2[lower..upper].each_with_index do |b, ib|
        ib += lower
        if a == b and !m2[ib]
          m, m1[ia], m2[ib] = m+1, ib, true
          break
        end
      end
    end

    return 0.0 if m.zero?
    
    m1.reduce do |a, b|
      # if either a or b are nil, that means there was no match
      # if a > b, that means the previous value is greater than the current
      # which means it went down
      if a > -1 and b > -1 and a > b
        t += (a-b > 1 ? 1 : 2)
      end
      b
    end

    dj = (m/s1s + m/s2s + (m - t/2)/m) / 3
    
    # winkler adjustment
    l = 0
    for i in 0..3
      if s1[i] != s2[i]
        l = i
        break
      end
    end

    # standard weight (p) for winkler == 0.1
    dj + l*0.1*(1-dj)
  end
end


