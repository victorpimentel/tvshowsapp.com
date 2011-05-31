#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'builder'

DEBUG = true # Pretty output and logs
SHOWRSS_LIST = "http://showrss.karmorra.info/?cs=feeds"
SHOWRSS_SHOW = "http://showrss.karmorra.info/feeds/{id}.rss"
EZRSS_LIST = "http://ezrss.it/shows/"
EZRSS_SHOW = "http://ezrss.it/search/index.php?show_name={name}&show_name_exact=true&mode=rss"
HAMSTER_LIST = "http://hamsterspit.com/shows/"
HAMSTER_SHOW = "http://hamsterspit.com{id}"
TVDB_SEARCH = "http://www.thetvdb.com/api/GetSeries.php?seriesname={name}"
TVDB_DETAILS = "http://www.thetvdb.com/data/series/{id}/en.xml"
YAHOO_PIPE = "http://pipes.yahoo.com/pipes/pipe.run?_id=5460d9047c41d2716eea73a27399b27a&_render=rss&filter={name}%20eztv&userName=eztv"

FIX_SHOW = {
  "30 Seconds AU" => "30 Seconds",
  "Archer" => "Archer (2009)",
  "Being Human" => "Being Human (US)",
  "Being Human US" => "Being Human (US)",
  "Big Brother US" => "Big Brother",
  "Big Brother Uk" => "Big Brother (UK)",
  "Bob's Burger" => "Bob's Burgers",
  "Brothers 2009" => "Brothers (2009)",
  "Castle" => "Castle (2009)",
  "Conan" => "Conan (2010)",
  "Doctor Who" => "Doctor Who (2005)",
  "David Letterman" => "Late Show with David Letterman",
  "Hells Kitchen" => "Hells Kitchen (US)",
  "Hells Kitchen US" => "Hells Kitchen (US)",
  "Kidnap & Ransom" => "Kidnap and Ransom",
  "MonsterQuest" => "Monster Quest",
  "Parenthood" => "Parenthood (2010)",
  "Parks & Recreation" => "Parks and Recreation",
  "Spicks & Specks" => "Spicks and Specks",
  "The Office" => "The Office (US)",
  "The Daily Show" => "The Daily Show with Jon Stewart",
  "The Killing" => "The Killing (2011)",
  "Two & a Half Men" => "Two and a Half Men",
  "Undercover Boss" => "Undercover Boss (US)",
  "Undercover Boss US" => "Undercover Boss (US)",
  "Who Do You Think You Are" => "Who Do You Think You Are (US)",
  "Who Do You Think You Are US" => "Who Do You Think You Are (US)"
}

class TVShowsIndex
  def initialize
    @shows = Hash.new
    @endedShows = Hash.new
  end

  def loadPreviousData(filename="showlist.xml", filename2="endedshows.xml")
    begin
      # Parse the previous xml with the show list
      doc = Nokogiri::XML(open(filename))
      shows = doc.css("show")

      # Each show...
      shows.each do |s|

        # Get the data
        show = Show.new s.css("name").first.inner_text
        show.realname = s.css("name").first.inner_text
        show.tvdbID = s.css("tvdbid").first.inner_text

        s.css("mirror").each do |m|
          show.mirrors.push m.inner_text
        end

        # Add the show to the array
        addShow(show)

      end
    rescue Exception => e
    end

    begin
      # Parse the previous xml with the ended show list
      doc = Nokogiri::XML(open(filename2))
      shows = doc.css("show")

      # Each show...
      shows.each do |s|

        # Get the data
        show = Show.new s.inner_text

        # Add the show to the array
        addShow(show, true)

      end
    rescue Exception => e
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

  def parseEZRSS
    # Parse the EZRSS page
    doc = Nokogiri::HTML(open(EZRSS_LIST))
    shows = doc.css(".con1 a")

    # Each show...
    shows.each do |s|
      if s["href"] =~ /search/
        # Get the data
        show = Show.new s.inner_text

        # Fix some duplicated shows
        if s.inner_text =~ /Merlin/
          show.realname = "Merlin"
          show.mirrors.push EZRSS_SHOW.sub("{name}", "Merlin").sub("&show_name_exact=true","")
        elsif s.inner_text == "Being Human"
          show.realname = "Being Human"
          show.mirrors.push EZRSS_SHOW.sub("{name}", "Being Human")
        elsif s.inner_text != "Archer" && # Shows to ignore
              s.inner_text != "BBC" &&
              s.inner_text != "Big Brother" &&
              s.inner_text != "Castle" &&
              s.inner_text != "Doctor Who" &&
              s.inner_text != "Hells Kitchen" &&
              s.inner_text != "How I Met Your Mother (" &&
              s.inner_text != "Monster Quest" &&
              s.inner_text != "Real Time With Bill Maher:" &&
              s.inner_text != "Victorias Secret Fashion Show" &&
              s.inner_text != "The Office US" &&
              s.inner_text != "The Tonight Show With Jay Leno"
          show.mirrors.push EZRSS_SHOW.sub("{name}", s.inner_text.gsub(/ +/, "+"))
        end

        puts "Found show #{show.name}" if DEBUG

        # Add the show to the array
        addShow(show)
      end
    end
  end

  def parseHamsterspit
    # Parse the ShowRSS page
    doc = Nokogiri::HTML(open(HAMSTER_LIST))
    shows = doc.css("li")

    # Each show...
    shows.each do |s|

      # Get the data
      show = Show.new s.css("a")[0].inner_text
      show.mirrors.push HAMSTER_SHOW.sub("{id}", s.css("a")[1]["href"])

      puts "Found show #{show.name}" if DEBUG
      puts "URL #{show.mirrors[0]}" if DEBUG

      # Add the show to the array
      addShow(show)

    end
  end

  def addShow(show, ended=false)
    # If the show is ended or we already know it, put it on the ended shows array
    if ended || @endedShows[show.name]
      puts "Adding ended show #{show.name}" if DEBUG
      @endedShows[show.name] = show
    # If the show exists, just append its mirrors
    elsif @shows[show.tvdbID]
      puts "Adding mirrors to show #{show.name}" if DEBUG
      @shows[show.tvdbID].mirrors |= show.mirrors
    # If the show is ended, put it on the ended shows array
    elsif show.isEnded?
      puts "Adding ended show #{show.name}" if DEBUG
      @endedShows[show.name] = show
    else
      puts "Adding show #{show.name}" if DEBUG
      @shows[show.tvdbID] = show
    end
  end

  def addTPBCustomFeeds
    # Each show add the yahoo pipe feed for eztv
    @shows.each do |id, show|
      show.mirrors |= [YAHOO_PIPE.sub("{name}", show.name).gsub(/\s+/, "%20")]
    end
  end

  def dumpShowsToRSS(filename="showlist.xml")
    xml = Builder::XmlMarkup.new(:indent => DEBUG ? 1 : 0)

    # Insert the required processing instruction
    xml.instruct!

    # Dump the show list
    xml.shows do
      @shows.sort_by{|show| show[1].name}.each do |id, show|
        xml.show do
          xml.name show.name
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
    xml = Builder::XmlMarkup.new(:indent => DEBUG ? 1 : 0)

    # Inser the required processing instruction
    xml.instruct!

    # Dump the show list
    xml.shows do
      @endedShows.sort.each do |name, show|
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

  def realname=(name)
    @name = name
  end

  def tvdbID
    return @tvdbID if @tvdbID

    # Search TVDB for this show name
    cleanName = URI.escape(name).gsub("&", "%26")
    tvdbSearchURL = TVDB_SEARCH.sub("{name}", cleanName)

    begin
      doc = Nokogiri::XML(open(tvdbSearchURL))
    rescue Exception => e
      return nil
    end

    results = doc.css("id")

    # Check if there are results
    return nil if !results.first

    # Search TVDB for this show status
    @tvdbID = results.first.inner_text
    @tvdbID = "74709" if cleanName == "Cops" # Fix Cops
    if @name == "Shameless" && @mirrors[0] =~ /showrss/ # Fix Shameless
      @name = "Shameless US"
      @tvdbID = "161511"
    end

    return @tvdbID
  end

  def isEnded?
    # Return cache version
    return @ended if @ended != nil

    return @ended = true if !self.tvdbID

    tvdbDetailsURL = TVDB_DETAILS.sub("{id}", @tvdbID)

    begin
      doc = Nokogiri::XML(open(tvdbDetailsURL))
    rescue Exception => e
      return @ended = true
    end

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
index.parseEZRSS
index.parseHamsterspit
index.addTPBCustomFeeds
index.dumpShowsToRSS
index.dumpEndedShowsToRSS
