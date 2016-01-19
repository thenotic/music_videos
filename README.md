# MusicVideos

To get an artist's music videos you need a lastfm api key as well as a youtube api key.

```ruby
v =  MusicVideos::Find.new(LASTFM_API_KEY,YOUTUBE_API_KEY)
music_videos = v.find_artist_music_videos("chief keef")

v.first
##<Object:0x007fe4ed1d2638 @artist="chief keef", @title="early morning getting it", @youtube_url="Mt07J2k8myM"> 
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'music_videos'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install music_videos

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/music_videos/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
