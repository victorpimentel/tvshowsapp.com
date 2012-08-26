#!/usr/bin/env ruby

require "rubygems"
require "open-uri"
require "nokogiri"
require "chronic"

require "app.rb"
require "models/parsed_episode.rb"

class TPBFetcher
	def fetch(filename)
		doc = Nokogiri::HTML(open(filename, "User-Agent" => TPB_USER_AGENT))
		items = doc.css("#searchResult tr td:nth-child(2)")

		items.each do |t|
			name = parse_name t
			link = parse_link t
			magnet = parse_magnet t
			uploader = parse_uploader t
			timestamp = parse_timestamp t
			size = parse_size t

			parsed_episode = ParsedEpisode.new(name, link, magnet, uploader, timestamp, size)

			next unless parsed_episode.is_valid?

			episode = parsed_episode.to_episode

			save_episode(episode) if episode.is_new?
			update_episode(episode) if episode.is_improvement?
		end
	end

	def fetch_with_steroids(show)
		fetch search_url(show.search + "%20-720p")
		fetch search_url(show.search + "%20720p")
		fetch search_url(show.search + "%20" + show.uploader) if (["eztv", "vtv"].include? show.uploader)
	end

	def save_episode(episode)
		episode.save
		LOGGER.info("Added #{episode.name}")
	end

	def update_episode(episode)
		episode.save_as_improvement
		LOGGER.info("Updated #{episode.name}")
	end

	def parse_name(el)
		el.css(".detName a").inner_text.gsub(NBSP, " ")
	end

	def parse_link(el)
		el.css(".detName a").attr("href").value.gsub(NBSP, " ").sub(/^\/torrent\//, "")
	end

	def parse_magnet(el)
		el.css("a[href^=magnet]").attr("href").value.gsub(NBSP, " ")
	end

	def parse_uploader(el)
		el.css("a.detDesc").inner_text.gsub(NBSP, " ").gsub(/[\{\}]/, ".").downcase
	end

	def parse_timestamp(el)
		details = parse_details el
		time = details.sub(/^Uploaded /, "").sub(/,.*/, "")
		time = time.sub("mins", "minutes").sub("Y-day", "Yesterday")
		time = time.sub(/([0-9]{2}).([0-9]{2}).([0-9]{2}).([0-9]{2})/, "\\1-\\2-12 \\3:\\4")
		time = time.sub(/([0-9]{2}).([0-9]{2}).([0-9]{4})/, "\\1-\\2-\\3")
		Chronic.parse(time)
	end

	def parse_size(el)
		details = parse_details el
		size = details.sub(/.*Size /, "").sub(/i?B.*,.*/, "")
		size.sub(/\.[0-9]?[0-9]?[^MG]+/, "").sub(/M/, "000").sub(/G/, "000000").to_i
	end

	def parse_details(el)
		el.css("font.detDesc").inner_text.to_s.gsub(NBSP, " ")
	end

	def search_url(search_term)
		TPB_SEARCH.sub(TERM_PLACEHOLDER, search_term).strip.gsub(/\s/, "%20")
	end
end
