require "music_videos/find"

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
  hydra = Typhoeus::Hydra.new
  yy.each do |x|
    url = "http://www.genyoutube.com/preview.php?id=#{x[1]}"
    request = Typhoeus::Request.new(url, followlocation: false)
    request.on_complete do |response|
      page = Nokogiri::HTML(response.body) rescue next
      image_url = page.css('img').select{|x| x.attr('src').to_s.include?('/M1')}[0].attr('src').to_s rescue next
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
#TO Run 
#v =  MusicVideos::Find.new("430711e29ad09c493dad2831eb0bbd08","AIzaSyBcfLnLUj1nQg_zA-NjQkMJfx-ccAQoYKc")
#music_videos = v.find_artist_music_videos


end
