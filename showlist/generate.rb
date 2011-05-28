#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'builder'

DEBUG = false # Pretty output and logs
SHOWRSS_LIST = "http://showrss.karmorra.info/?cs=feeds"
SHOWRSS_SHOW = "http://showrss.karmorra.info/feeds/{id}.rss"
EZRSS_LIST = "http://ezrss.it/shows/"
TVDB_SEARCH = "http://www.thetvdb.com/api/GetSeries.php?seriesname={name}&language=all"
TVDB_DETAILS = "http://www.thetvdb.com/data/series/{id}/"

FIX_SHOW = {
  "30 Seconds AU" => "30 Seconds",
  "Archer" => "Archer (2009)",
  "Big Brother US" => "Big Brother",
  "Bob's Burger" => "Bob's Burgers",
  "Castle" => "Castle (2009)",
  "Conan" => "Conan (2010)",
  "Doctor Who" => "Doctor Who (2005)",
  "David Letterman" => "Late Show with David Letterman",
  "Kidnap & Ransom" => "Kidnap and Ransom",
  "MonsterQuest" => "Monster Quest",
  "Parenthood" => "Parenthood (2010)",
  "Parks & Recreation" => "Parks and Recreation",
  "Spicks & Specks" => "Spicks and Specks",
  "The Office" => "The Office (US)",
  "The Daily Show" => "The Daily Show with Jon Stewart",
  "The Killing" => "The Killing (2011)",
  "Two & a Half Men" => "Two and a Half Men"
}

class TVShowsIndex
  def initialize
    @shows = Hash.new
    @endedShows = Hash.new
  end

  def loadPreviousData(filename="showlist.xml")
    # Parse the previous xml with the show list
    doc = Nokogiri::XML(open(filename))
    shows = doc.css("show")

    # Each show...
    shows.each do |s|

      # Get the data
      show = Show.new s.css("name").first.inner_text
      show.tvdbID = s.css("tvdbid").first.inner_text

      s.css("mirror").each do |m|
        show.mirrors.push m.inner_text
      end

      # Add the show to the array
      addShow(show)

    end
  end

  def parseShowRSS
    # Parse the ShowRSS page
    doc = Nokogiri::HTML(open(SHOWRSS_LIST))
    shows = doc.css("[name='show'] option")

    # Each show...
    shows.each do |s|

      # Get the data
      show = Show.new s.inner_text
      show.mirrors.push SHOWRSS_SHOW.sub("{id}", s["value"])

      puts "Found show #{show.name}" if DEBUG

      # Add the show to the array
      addShow(show)

    end
  end

  def addShow(show)
    # If the show exists, just append its mirrors
    if @shows[show.name]
      puts "Adding mirrors to show #{show.name}" if DEBUG
      @shows[show.name].mirrors |= show.mirrors
    # If the show is ended, put it on the ended shows array
    elsif show.isEnded?
      puts "Adding ended show #{show.name}" if DEBUG
      @endedShows[show.name] = show
    else
      puts "Adding show #{show.name}" if DEBUG
      @shows[show.name] = show
    end
  end

  def dumpShowsToRSS(filename="showlist.xml")
    xml = Builder::XmlMarkup.new(:indent => DEBUG ? 2 : 0)

    # Insert the required processing instruction
    xml.instruct!

    # Dump the show list
    xml.shows do
      @shows.each do |name, show|
        xml.show do
          xml.name name
          xml.tvdbid show.tvdbID
          xml.mirrors do
            show.mirrors.each do |mirror|
              xml.mirror mirror
            end
          end
        end
      end
    end

    # Dump it to the xml file
    File.open(filename,"w") do |f|
      f.write(xml.target!)
    end
  end

  def dumpEndedShowsToRSS(filename="endedshows.xml")
    xml = Builder::XmlMarkup.new(:indent => DEBUG ? 2 : 0)

    # Inser the required processing instruction
    xml.instruct!

    # Dump the show list
    xml.shows do
      @endedShows.each do |name, show|
        xml.show name
      end
    end

    # Dump it to the xml file
    File.open(filename,"w") do |f|
      f.write(xml.target!)
    end
  end

end

class Show
  attr_accessor :name, :mirrors, :tvdbID

  def initialize(name)
    self.name = name
    @mirrors = []
  end

  def name=(name)
    name = name.gsub(/\s+/, " ").gsub(/ [aA]nd /, " & ").strip

    # Correct names
    name = FIX_SHOW[name] || name

    @name = name
  end

  def tvdbID
    return @tvdbID if @tvdbID

    # Search TVDB for this show name
    cleanName = URI.escape(name).gsub("&", "%26")
    tvdbSearchURL = TVDB_SEARCH.sub("{name}", cleanName)
    doc = Nokogiri::XML(open(tvdbSearchURL))
    results = doc.css("id")

    # Check if there are results
    return nil if !results.first

    # Search TVDB for this show status
    @tvdbID = results.first.inner_text
    @tvdbID = "74709" if cleanName == "Cops" # Fix Cops

    return @tvdbID
  end

  def isEnded?
    # Return cache version
    return @ended if @ended != nil

    tvdbDetailsURL = TVDB_DETAILS.sub("{id}", self.tvdbID)
    doc = Nokogiri::XML(open(tvdbDetailsURL))
    results = doc.css("Status")

    # Check if there are results
    return @ended = true if (!results.first)

    # Finally return the proper value
    return @ended = (results.first.inner_text == "Ended")
  end
end

index = TVShowsIndex.new
index.loadPreviousData
index.parseShowRSS
index.dumpShowsToRSS
index.dumpEndedShowsToRSS
