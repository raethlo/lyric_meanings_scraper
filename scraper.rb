# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# require 'scraperwiki'
# require 'mechanize'
#
# agent = Mechanize.new
#
# # Read in a page
# page = agent.get("http://foo.com")
#
# # Find somehing on the page using css selectors
# p page.at('div.content')
#
# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".

require 'scraperwiki'
require 'faraday'
require 'nokogiri'

def open_page(id)
  url = "http://songmeanings.com/songs/view/#{id}"

  html = Faraday.get url
  doc = Nokogiri.HTML html.body
end

def scrape_lyric(doc)
  bread = doc.css('ul.breadcrumbs')
  navigation = bread.css('li')

  _, artist, album, song = navigation.map { |li| li.text.strip }

  lyrics_box = doc.css('div.lyric-box')
  lyrics_box.children.css('div').remove

  lyrics = lyrics_box.text

  {
      artist: artist,
      album: album,
      song: song,
      lyrics: lyrics
  }
end

#
i = 1

10.times do
  begin
    page = open_page(i)
    data = scrape_lyric(page)

    if (ScraperWiki.select("* from lyrics where `artist`='#{data[:artist]}' and `song`='#{data[:song]}'").empty? rescue true)
      ScraperWiki.save_sqlite(
        ["lyrics"],
        {
            "artist" => data[:artist],
            "album" => data[:album],
            "song" => data[:song],
            "lyrics" => data[:lyrics]
        }
      )
    else
      puts "Lyrics for #{data[:artist]} and song #{data[:song]} already there"
    end

    i += 1

  rescue => e
    puts e.message
  end
end