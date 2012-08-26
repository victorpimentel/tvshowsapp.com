#!/usr/bin/env ruby
$LOAD_PATH << '/home/victorpimentel/tvshowsapp.com/feeds/'

require "rubygems"
require "open-uri"
require "nokogiri"
require 'thor'

require "app.rb"
require "models/show.rb"
require "models/episode.rb"
require "feed_generator.rb"

class FeedManager < Thor
	include Thor::Actions

	desc "generate_all_feeds", "Generate feeds for all shows."
	def generate_all_feeds()
		begin
			generator = FeedGenerator.new
			Show.find(:all).each do |show|
				generator.generate show

				LOGGER.info "Generated feed for show #{show.name}."
			end
		rescue Exception => e
			LOGGER.error e
		end
	end

	desc "generate_for_show [SEARCH]", "Generate feed for a show."
	def generate_for_show(search = nil)
		return if !search || search.length < 5

		begin
			show = Show.find_by_search(search)

			generator = FeedGenerator.new
			generator.generate show if show

			LOGGER.info "Generated feed for show #{show.name}."
		rescue Exception => e
			LOGGER.error e
		end
	end
end

FeedManager.start if __FILE__ == $0
