#!/usr/bin/env ruby
$LOAD_PATH << '/home/victorpimentel/tvshowsapp.com/feeds/'

require "rubygems"
require "open-uri"
require 'builder'
require 'thor'

require "app.rb"
require "models/show.rb"

class ShowlistGenerator < Thor
	include Thor::Actions

	desc "dump_showlist [FILENAME]", "Generate the showlist file."
	def dump_showlist(filename=SHOWLIST_FILE)
		xml = Builder::XmlMarkup.new(:indent => DEBUG ? 1 : 0)

		# Insert the required processing instruction
		xml.instruct!

		# Dump the show list
		xml.shows do
			Show.order("name").find_all_by_status("airing", "upcoming").each do |show|
				xml.show do
					xml.name show.name
					xml.tvdbid show.tvdb_id
					xml.added show.created_at
					xml.mirrors do
						xml.mirror show.feed_url
					end
				end
			end
		end

		# Dump it to the xml file
		File.open(MY_PATH + filename,"w") do |f|
			f.write(xml.target!)
		end

		LOGGER.info "Generated showlist."
	end
end

ShowlistGenerator.start if __FILE__ == $0
