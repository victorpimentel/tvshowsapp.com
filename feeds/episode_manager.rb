#!/usr/bin/env ruby
$LOAD_PATH << '/home/victorpimentel/tvshowsapp.com/feeds/'

require "rubygems"
require "open-uri"
require "nokogiri"
require 'thor'

require "app.rb"
require "models/show.rb"
require "episode_tpb_fetcher.rb"
require "episode_eztv_fetcher.rb"

class EpisodeManager < Thor
	include Thor::Actions

	desc "populate [FIRST LAST]", "Import old episodes."
	def populate(first = 0, last = INFINITY)
		first = first.to_i
		last = last.to_f

		begin
			fetcher = TPBFetcher.new

			Show.find(:all).each do |show|
				if show.id >= first && show.id <= last
					fetcher.fetch_with_steroids show
				end
			end
		rescue Exception => e
			LOGGER.error e
		end
	end

	desc "update_from_tpb", "Import new episodes from TPB."
	def update_from_tpb()
		begin
			fetcher = TPBFetcher.new()
			fetcher.fetch TPB_GENERIC_SEARCH_SD
			fetcher.fetch TPB_GENERIC_SEARCH_HD
		rescue Exception => e
			LOGGER.error e
		end
	end

	desc "update_from_eztv", "Import new episodes from EZTV."
	def update_from_eztv()
		begin
			fetcher = EZTVFetcher.new()
			fetcher.fetch
		rescue Exception => e
			LOGGER.error e
		end
	end
end

EpisodeManager.start if __FILE__ == $0
