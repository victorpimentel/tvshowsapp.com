#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'builder'

DEBUG = true # Pretty output and logs
SHOWRSS_LIST = "http://showrss.info/?cs=feeds"
SHOWRSS_SHOW = "http://showrss.info/feeds/{id}.rss"
EZRSS_LIST = "http://ezrss.it/shows/"
EZRSS_SHOW = "http://ezrss.it/search/index.php?show_name={name}&show_name_exact=true&mode=rss"
HAMSTER_LIST = "http://hamsterspit.com/shows/"
HAMSTER_SHOW = "http://hamsterspit.com{id}/"
BITSNOOP_LIST = "http://bitsnoop.com/tvrss/"
BITSNOOP_SHOW = "http://bitsnoop.com/tvrss.xml?shows={id}"
TVDB_SEARCH = "http://www.thetvdb.com/api/GetSeries.php?seriesname={name}"
TVDB_DETAILS = "http://www.thetvdb.com/data/series/{id}/en.xml"
YAHOO_PIPE_BRIDGE = "http://tvshowsapp.com/feed/?filter={name}&userName={user}"

FIX_SHOW = {
  "30 Seconds AU" => "30 Seconds",
  "Archer" => "Archer (2009)",
  "Being Human US" => "Being Human (US)",
  "Bob's Burger" => "Bob's Burgers",
  "Brothers 2009" => "Brothers (2009)",
  "Castle" => "Castle (2009)",
  "Conan" => "Conan (2010)",
  "COPS" => "Cops",
  "CSI" => "CSI: Crime Scene Investigation",
  "Doctor Who" => "Doctor Who (2005)",
  "David Letterman" => "Late Show with David Letterman",
  "Hells Kitchen" => "Hell's Kitchen",
  "Hells Kitchen US" => "Hell's Kitchen",
  "Hell's Kitchen (US)" =>  "Hell's Kitchen",
  "House M.D." => "House",
  "House, M.D." => "House",
  "Iron Chef America: The Series" => "Iron Chef America",
  "King" => "King (2011)",
  "Love Bites" => "Love Bites (2011)",
  "Louie" => "Louie (2010)",
  "MonsterQuest" => "Monster Quest",
  "Navy NCIS: Naval Criminal Investigative Service" => "NCIS",
  "NCIS LA" => "NCIS: Los Angeles",
  "Parenthood" => "Parenthood (2010)",
  "Parks & Recreation" => "Parks and Recreation",
  "Shameless" => "Shameless (US)",
  "Shameless (UK)" => "Shameless (US)",
  "Shameless US" => "Shameless (US)",
  "Spicks & Specks" => "Spicks and Specks",
  "Star Wars The Clone Wars 2008" => "Star Wars: The Clone Wars",
  "Star Wars: Clone Wars" => "Star Wars: The Clone Wars",
  "Star Wars: The Clone Wars (2008)" => "Star Wars: The Clone Wars",
  "Teen Wolf (2011)" => "Teen Wolf",
  "The Office" => "The Office (US)",
  "The Daily Show" => "The Daily Show with Jon Stewart",
  "The Hour UK 2011" => "The Hour (2011)",
  "The Killing" => "The Killing (2011)",
  "The Lying Game (2011)" => "The Lying Game",
  "Thundercats" => "Thundercats (2011)",
  "Two & a Half Men" => "Two and a Half Men",
  "Undercover Boss" => "Undercover Boss (US)",
  "Undercover Boss US" => "Undercover Boss (US)",
  "Wallander" => "Wallander (UK)",
  "Who Do You Think You Are" => "Who Do You Think You Are (US)",
  "Who Do You Think You Are US" => "Who Do You Think You Are (US)",
  "Wilfred" => "Wilfred (US)",

  # These shows are removed from the EZTV list,
  # mostly ongoing shows not supported anymore by EZTV
  "Accidental Heroes" => "REMOVE FROM THE LIST",
  "After the Catch" => "REMOVE FROM THE LIST",
  "Alice" => "REMOVE FROM THE LIST",
  "Alive" => "REMOVE FROM THE LIST",
  "Americas Funniest Home Videos" => "REMOVE FROM THE LIST",
  "Americas Got Talent" => "REMOVE FROM THE LIST",
  "Anchorwoman" => "REMOVE FROM THE LIST",
  "Austin City Limits" => "REMOVE FROM THE LIST",
  "Australian Idol" => "REMOVE FROM THE LIST",
  "Big Brother" => "REMOVE FROM THE LIST",
  "Big Brother US" => "REMOVE FROM THE LIST",
  "Big Brother Uk" => "REMOVE FROM THE LIST",
  "The Bachelor" => "REMOVE FROM THE LIST",
  "The Backyardigans" => "REMOVE FROM THE LIST",
  "Bad Universe" => "REMOVE FROM THE LIST",
  "BBC This World" => "REMOVE FROM THE LIST",
  "BET Hip Hop Awards" => "REMOVE FROM THE LIST",
  "Big Brother's Little Brother" => "REMOVE FROM THE LIST",
  "Big Brothers Little Brother" => "REMOVE FROM THE LIST",
  "Big Brother's Big Mouth" => "REMOVE FROM THE LIST",
  "Big Brothers Big Mouth" => "REMOVE FROM THE LIST",
  "Bigger Stronger Faster" => "REMOVE FROM THE LIST",
  "The Biggest Loser" => "REMOVE FROM THE LIST",
  "British Painting" => "REMOVE FROM THE LIST",
  "Brothers (2009)" => "REMOVE FROM THE LIST",
  "Bullrun" => "REMOVE FROM THE LIST",
  "Cash Poker" => "REMOVE FROM THE LIST",
  "Cheerleader U" => "REMOVE FROM THE LIST",
  "Christmas In Rockefeller Center" => "REMOVE FROM THE LIST",
  "Cities of the Underworld" => "REMOVE FROM THE LIST",
  "City Homicide" => "REMOVE FROM THE LIST",
  "Clash of the Choirs" => "REMOVE FROM THE LIST",
  "The CollegeHumor Show" => "REMOVE FROM THE LIST",
  "Comedy Lab" => "REMOVE FROM THE LIST",
  "The Contender" => "REMOVE FROM THE LIST",
  "Criss Angel Mindfreak" => "REMOVE FROM THE LIST",
  "Daily Cowboys Cheerleaders Making The Team" => "REMOVE FROM THE LIST",
  "Dallas Cowboys Cheerleaders Making The Team" => "REMOVE FROM THE LIST",
  "Dancelife" => "REMOVE FROM THE LIST",
  "Dave Gorman in America Unchained" => "REMOVE FROM THE LIST",
  "Deadliest Warrior" => "REMOVE FROM THE LIST",
  "Deep Wreck Mysteries" => "REMOVE FROM THE LIST",
  "Delocated" => "REMOVE FROM THE LIST",
  "Dirk Gently" => "REMOVE FROM THE LIST",
  "Discovery Channel Egypt Uncovered" => "REMOVE FROM THE LIST",
  "Dogface" => "REMOVE FROM THE LIST",
  "Durham County" => "REMOVE FROM THE LIST",
  "E True Hollywood Story" => "REMOVE FROM THE LIST",
  "E2 Transport" => "REMOVE FROM THE LIST",
  "Early Renaissance Painting" => "REMOVE FROM THE LIST",
  "Extreme Makeover Home Edition" => "REMOVE FROM THE LIST",
  "Factory" => "REMOVE FROM THE LIST",
  "The Fairly OddParents" => "REMOVE FROM THE LIST",
  "The Family" => "REMOVE FROM THE LIST",
  "Flash Gordon" => "REMOVE FROM THE LIST",
  "Frank TV" => "REMOVE FROM THE LIST",
  "Gangland" => "REMOVE FROM THE LIST",
  "Gene Simmons Family Jewels" => "REMOVE FROM THE LIST",
  "Get Lost" => "REMOVE FROM THE LIST",
  "The Girls Next Door" => "REMOVE FROM THE LIST",
  "Glamour Girls" => "REMOVE FROM THE LIST",
  "Good Eats" => "REMOVE FROM THE LIST",
  "Good Game" => "REMOVE FROM THE LIST",
  "Good Luck Charlie" => "REMOVE FROM THE LIST",
  "The Guard" => "REMOVE FROM THE LIST",
  "Halfway Home" => "REMOVE FROM THE LIST",
  "The Hard Times of RJ Berger" => "REMOVE FROM THE LIST",
  "High Stakes Poker" => "REMOVE FROM THE LIST",
  "The Hollowmen" => "REMOVE FROM THE LIST",
  "Horizon" => "REMOVE FROM THE LIST",
  "How Stuff Works" => "REMOVE FROM THE LIST",
  "How To Look Good Naked" => "REMOVE FROM THE LIST",
  "Hows Your News" => "REMOVE FROM THE LIST",
  "iCarly" => "REMOVE FROM THE LIST",
  "In Hamrs Way" => "REMOVE FROM THE LIST",
  "Inked" => "REMOVE FROM THE LIST",
  "Inside The Actors Studio" => "REMOVE FROM THE LIST",
  "James May's Man Lab" => "REMOVE FROM THE LIST",
  "The Jay Leno Show" => "REMOVE FROM THE LIST",
  "Jeopardy" => "REMOVE FROM THE LIST",
  "Jeopardy!" => "REMOVE FROM THE LIST",
  "Jurassic Fight Club" => "REMOVE FROM THE LIST",
  "Justice" => "REMOVE FROM THE LIST",
  "Kidnap & Ransom" => "REMOVE FROM THE LIST",
  "Lewis Blacks Root Of All Evil" => "REMOVE FROM THE LIST",
  "The Line" => "REMOVE FROM THE LIST",
  "Living With The Kombai Tribe" => "REMOVE FROM THE LIST",
  "Lost Worlds" => "REMOVE FROM THE LIST",
  "Larry King Live" => "REMOVE FROM THE LIST",
  "MADtv" => "REMOVE FROM THE LIST",
  "Mad" => "REMOVE FROM THE LIST",
  "Miami Ink" => "REMOVE FROM THE LIST",
  "Mind of Mencia" => "REMOVE FROM THE LIST",
  "Miss Universe Pageant" => "REMOVE FROM THE LIST",
  "Missing 2009" => "REMOVE FROM THE LIST",
  "Modern Marvels" => "REMOVE FROM THE LIST",
  "The Mole" => "REMOVE FROM THE LIST",
  "Monkey Life" => "REMOVE FROM THE LIST",
  "MTV Video Music Awards" => "REMOVE FROM THE LIST",
  "My Fair Brady" => "REMOVE FROM THE LIST",
  "My Family" => "REMOVE FROM THE LIST",
  "National Geographic" => "REMOVE FROM THE LIST",
  "National Geographic Megastructures" => "REMOVE FROM THE LIST",
  "National Geographic Naked Science" => "REMOVE FROM THE LIST",
  "NatureTech" => "REMOVE FROM THE LIST",
  "NFL" => "REMOVE FROM THE LIST",
  "Nick Swardsons Pretend Time" => "REMOVE FROM THE LIST",
  "No Maps For These Territories" => "REMOVE FROM THE LIST",
  "The No. 1 Ladies Detective Agency" => "REMOVE FROM THE LIST",
  "The No 1 Ladies Detective Agency" => "REMOVE FROM THE LIST",
  "On The Lot" => "REMOVE FROM THE LIST",
  "Outer Space Astronauts" => "REMOVE FROM THE LIST",
  "Panorama" => "REMOVE FROM THE LIST",
  "The Paper" => "REMOVE FROM THE LIST",
  "Paris Hilton British Best Friend" => "REMOVE FROM THE LIST",
  "Paris Hiltons British Best Friend" => "REMOVE FROM THE LIST",
  "The Penguins Of Madagascar" => "REMOVE FROM THE LIST",
  "The Penguins of Madagascar" => "REMOVE FROM THE LIST",
  "Pen & Teller Fool Us" => "REMOVE FROM THE LIST",
  "Penn And Teller Fool Us" => "REMOVE FROM THE LIST",
  "Person of Interest" => "REMOVE FROM THE LIST",
  "Pioneer One" => "REMOVE FROM THE LIST",
  "Phenomenon" => "REMOVE FROM THE LIST",
  "Phineas & Ferb" => "REMOVE FROM THE LIST",
  "Phoenix Mars Mission Ashes to Ice" => "REMOVE FROM THE LIST",
  "Poirot (Agatha Christie's)" => "REMOVE FROM THE LIST",
  "The Poker Star" => "REMOVE FROM THE LIST",
  "Poker Superstars" => "REMOVE FROM THE LIST",
  "Pretty Handsome" => "REMOVE FROM THE LIST",
  "The Price is Right" => "REMOVE FROM THE LIST",
  "Professional Poker Tour" => "REMOVE FROM THE LIST",
  "Prototype This" => "REMOVE FROM THE LIST",
  "Project Catwalk" => "REMOVE FROM THE LIST",
  "Project Runway Australia" => "REMOVE FROM THE LIST",
  "Project Runway Canada" => "REMOVE FROM THE LIST",
  "Pulse" => "REMOVE FROM THE LIST",
  "QI XL" => "REMOVE FROM THE LIST",
  "Reagan" => "REMOVE FROM THE LIST",
  "The Real World" => "REMOVE FROM THE LIST",
  "Red Dwarf" => "REMOVE FROM THE LIST",
  "Retired at 35" => "REMOVE FROM THE LIST",
  "The Rock Life" => "REMOVE FROM THE LIST",
  "Ross Nobles Australian Trip" => "REMOVE FROM THE LIST",
  "Royal Institution Christmas Lectures" => "REMOVE FROM THE LIST",
  "Run's House" => "REMOVE FROM THE LIST",
  "Saving Planet Earth" => "REMOVE FROM THE LIST",
  "Shaqs Big Challenge" => "REMOVE FROM THE LIST",
  "Silent Witness" => "REMOVE FROM THE LIST",
  "The Simple Life" => "REMOVE FROM THE LIST",
  "The Singing Bee" => "REMOVE FROM THE LIST",
  "Snapped" => "REMOVE FROM THE LIST",
  "Snoop Doggs Father Hood" => "REMOVE FROM THE LIST",
  "Somebodies" => "REMOVE FROM THE LIST",
  "So You Think You Can Dance (UK)" => "REMOVE FROM THE LIST",
  "So You Think You Can Dance Canada" => "REMOVE FROM THE LIST",
  "SpongeBob SquarePants" => "REMOVE FROM THE LIST",
  "Street Customs" => "REMOVE FROM THE LIST",
  "Tell Me You Love Me" => "REMOVE FROM THE LIST",
  "Things We Love To Hate" => "REMOVE FROM THE LIST",
  "Two Pints Of Lager & A Packet Of Crisps" => "REMOVE FROM THE LIST",
  "Upstairs Downstairs" => "REMOVE FROM THE LIST",
  "Upstairs Downstairs 2010" => "REMOVE FROM THE LIST",
  "Vegas Confessions" => "REMOVE FROM THE LIST",
  "Wallander" => "REMOVE FROM THE LIST",
  "Whale Wars" => "REMOVE FROM THE LIST",
  "Whistle & Ill Come To You" => "REMOVE FROM THE LIST",
  "Wire Science" => "REMOVE FROM THE LIST",
  "World Poker Tour" => "REMOVE FROM THE LIST",
  "World Series of Poker" => "REMOVE FROM THE LIST"
}

TPB_CORRECTIONS = {
  "The Amazing Race" => "The Amazing Race -AU -Australia",
  "The Amazing Race Australia" => "The Amazing Race AU",
  "The Apprentice" => "The Apprentice -UK",
  "Being Human" => "Being Human -US",
  "Big Brother" => "Big Brother US",
  "The Big C" => "The Big C -Bang",
  "Britain's Got Talent" => "Britains Got Talent",
  "Comedy Central Presents" => "Comedy Central Presents -pdtv -S13* -S14*",
  "Conan (2010)" => "Conan",
  "CSI: Crime Scene Investigation" => "CSI -miami -ny -new",
  "CSI: NY" => "CSI New York",
  "The Daily Show with Jon Stewart" => "The Daily Show",
  "Dancing With The Stars" => "Dancing With The Stars -AU",
  "Dancing With The Stars (Australia)" => "Dancing With The Stars AU",
  "Dirty Money" => "Dirty Money -Sexy",
  "Downton Abbey" => "Downton Abbey -Hero",
  "The Firm" => "The Firm -dvdrip",
  "The Game" => "The Game -Lying -Plan",
  "Ghost Hunters" => "Ghost Hunters -International avi",
  "Glee" => "Glee -Encore -Project",
  "Gran Reserva" => "Gran Reserva -dvdrip",
  "Grand Designs" => "Grand Designs -Australia",
  "Homeland" => "Homeland -2010",
  "Hulk Hogan's Micro Championship Wrestling" => "Hulk Hogans MCW",
  "The Increasingly Poor Decisions of Todd Margaret" => "The Increasingly Poor Decisions of Todd Margaret",
  "Jimmy Kimmel Live" => "Jimmy Kimmel",
  "King" => "King 2HD",
  "The Killing (2011)" => "The Killing",
  "Last Man Standing (2011)" => "Last Man Standing -1996 -2008",
  "Late Show with David Letterman" => "David Letterman",
  "Late Night with Jimmy Fallon" => "Jimmy Fallon",
  "Louie (2010)" => "Louie",
  "Man Up!" => "Man Up",
  "NCIS" => "NCIS -Angeles",
  "NTSF:SD:SUV" => "NTSF SD SUV",
  "Once Upon A Time (2011)" => "Once Upon A Time",
  "The Only Way Is Essex" => "The Only Way Is Essex -dvdrip",
  "Parenthood (2010)" => "Parenthood",
  "Person of Interest" => "Person of Interest -2007",
  "Project Runway" => "Project Runway -AU",
  "The River (2011)" => "The River -Murders",
  "Top Chef" => "Top Chef -Masters -Desserts",
  "Top Gear" => "Top Gear -US -Australia",
  "Tosh.0" => "Tosh 0",
  "Shameless" => "Shameless -US",
  "Shut Up!" => "Shut Up",
  "Unforgettable" => "Unforgettable -2010 -2008",
  "Skins" => "Skins -US",
  "Whitney" => "Whitney -Cummings",
  "The X Factor" => "The X Factor -US",
  "Young Justice" => "Young Justice -web"
}

TPB_USER = {
  "Alphas" => "vtv",
  "Burn Notice" => "vtv",
  "Chaos" => "vtv",
  "The Closer" => "vtv",
  "The Colbert Report" => "vtv",
  "The Daily Show with Jon Stewart" => "vtv",
  "Flashpoint" => "vtv",
  "Franklin & Bash" => "vtv",
  "Glee" => "vtv",
  "The Good Wife" => "vtv",
  "How I Met Your Mother" => "vtv",
  "The Killing (2011)" => "vtv",
  "New Tricks" => "vtv",
  "NCIS" => "vtv",
  "NCIS: Los Angeles" => "vtv",
  "Nikita" => "vtv",
  "Real Time with Bill Maher" => "vtv",
  "Ringer" => "vtv",
  "Rizzoli & Isles" => "vtv",
  "Shameless" => "sceneline",
  "Shameless (US)" => "vtv",
  "Suits" => "vtv",
  "Torchwood" => "vtv",
  "Warehouse 13" => "vtv",
  "Web Therapy" => "vtv",
  "Wilfred (US)" => "vtv",

  "16 and Pregnant" => "TvTeam",
  "The Almighty Johnsons" => "TvTeam",
  "The Amazing Race Australia" => "TvTeam",
  "Are We There Yet?" => "TvTeam",
  "Argumental" => "TvTeam",
  "Army Wives" => "TvTeam",
  "The Bad Girls Club" => "TvTeam",
  "Bethenny Ever After" => "TvTeam",
  "Billy Connolly's Route 66" => "TvTeam",
  "Blue Mountain State" => "TvTeam",
  "Britain's Got Talent" => "TvTeam",
  "Celebrity Rehab with Dr. Drew" => "TvTeam",
  "Childrens Hospital" => "TvTeam",
  "Comedy Central Presents" => "TvTeam",
  "Crownies" => "TvTeam",
  "Doc Martin" => "TvTeam",
  "Downton Abbey" => "TvTeam",
  "Foyle's War" => "TvTeam",
  "Gene Simmons: Family Jewels" => "TvTeam",
  "Ghost Hunters International" => "TvTeam",
  "The Glee Project" => "TvTeam",
  "H8R" => "TvTeam",
  "Have I Got News For You" => "TvTeam",
  "Hulk Hogan's Micro Championship Wrestling" => "TvTeam",
  "Ideal" => "TvTeam",
  "Iron Chef America" => "TvTeam",
  "IRT Deadliest Roads" => "TvTeam",
  "Jimmy Kimmel Live" => "TvTeam",
  "Late Night with Jimmy Fallon" => "TvTeam",
  "The Little Couple" => "TvTeam",
  "Metalocalypse" => "TvTeam",
  "Miranda" => "TvTeam",
  "Never Mind The Buzzcocks" => "TvTeam",
  "Not Going Out" => "TvTeam",
  "NTSF:SD:SUV" => "TvTeam",
  "The Only Way Is Essex" => "TvTeam",
  "Outnumbered" => "TvTeam",
  "Police Women of Broward County" => "TvTeam",
  "Project Runway" => "TvTeam",
  "The Real Housewives of Atlanta" => "TvTeam",
  "The Real Housewives of Beverly Hills" => "TvTeam",
  "The Real Housewives of DC" => "TvTeam",
  "The Real Housewives of Miami" => "TvTeam",
  "The Real Housewives of New Jersey" => "TvTeam",
  "The Real Housewives of New York City" => "TvTeam",
  "The Real Housewives of Orange County" => "TvTeam",
  "The Real Hustle" => "TvTeam",
  "Republic of Doyle" => "TvTeam",
  "Rob Dyrdek's Fantasy Factory" => "TvTeam",
  "Russell Howard's Good News" => "TvTeam",
  "Spirited" => "TvTeam",
  "Storm Chasers" => "TvTeam",
  "The Soup" => "TvTeam",
  "Take the Money and Run" => "TvTeam",
  "This Is Jinsy" => "TvTeam",
  "This Is Not My Life" => "TvTeam",
  "Top Chef Masters" => "TvTeam",
  "Top Chef: Just Desserts" => "TvTeam",
  "Top Shot" => "TvTeam",
  "Tosh.0" => "TvTeam",
  "Up All Night" => "TvTeam",
  "White Van Man (2011)" => "TvTeam",
  "Wizards of Waverly Place" => "TvTeam",
  "Would I Lie To You?" => "TvTeam",
  "Young Justice" => "TvTeam",

  "Batman: The Brave & the Bold" => "despo1ler",
  "Crematorio" => "hero14",
  "Damages" => "fredyr",
  "Ghost Hunters" => "trialNerror",
  "Gran Reserva" => "carambolas",
  "Grand Designs" => "scenebalance",
  "Jersey Shore" => "scenebalance",
  "Top Gear (US)" => "wilimaw",
  "Top Gear Australia" => "tonyisaac"
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
          show.mirrors.push EZRSS_SHOW.sub("{name}", s.inner_text.gsub(/ +/, "+").gsub(/&/, "%26"))
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

  def parseBitSnoop
    # Parse the ShowRSS page
    doc = Nokogiri::HTML(open(BITSNOOP_LIST))
    shows = doc.css("[name='shows'] option")

    # Each show...
    shows.each do |s|

      # Get the data
      show = Show.new s.inner_text.gsub(/(.+), The/, "The \\1")
      show.mirrors.push BITSNOOP_SHOW.sub("{id}", s["value"])

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

  def addCustomFeeds
    # Each show add the yahoo pipe feed for eztv
    @shows.each do |id, show|
      user = TPB_USER[show.name] || "eztv"
      name = TPB_CORRECTIONS[show.name] || show.name
      name = name + " " + user if user == "eztv" || user == "vtv"
      show.mirrors |= [YAHOO_PIPE_BRIDGE.sub("{name}", name.gsub(/[&']/, "")).sub("{user}", user).gsub(/\s+/, "%20")]
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
              xml.mirror mirror unless mirror =~ /bitsnoop/
            end
          end
          if show.mirrors.select{|m| m =~ /bitsnoop/}.size > 0
            xml.mirrors2 do
              show.mirrors.each do |mirror|
                xml.mirror mirror if mirror =~ /bitsnoop/
              end
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
    elsif @name == "Merlin" # Fix Merlin
      @tvdbID = "83123"
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
#index.parseHamsterspit
index.parseBitSnoop
ARGV.map {|s| index.addShow Show.new(s)}
index.addCustomFeeds
index.dumpShowsToRSS
index.dumpEndedShowsToRSS
