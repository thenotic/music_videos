require 'music_videos'

describe MusicVideos::Find do
  it "fuckface" do
    expect(MusicVideos::Find.new("430711e29ad09c493dad2831eb0bbd08","AIzaSyBcfLnLUj1nQg_zA-NjQkMJfx-ccAQoYKc").artist_search("chief keef")).to eql("Chief+Keef")
  end

 
end