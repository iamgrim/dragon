require 'lastfm'

class Lastfm
  class Group < MethodCategory
    def get_weekly_artist_chart(group)
      request('getWeeklyArtistChart', {
        :group => group
      })
    end
  end
  
  class User < MethodCategory
    def get_recent_tracks(user_name, limit = 15)
      request('getRecentTracks', {
        :user => user_name, 
        :limit => limit
      })
    end
  end
end