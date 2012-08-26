#!/usr/bin/env ruby

require "rubygems"
require "open-uri"
require "nokogiri"
require "chronic"

require "app.rb"
require "models/parsed_episode.rb"

class EZTVFetcher
	def fetch
		doc = Nokogiri::HTML(open(EZTV_GENERIC_SEARCH, "User-Agent" => TPB_USER_AGENT))
		items = doc.css("tr.forum_header_border")

		items.each do |t|
			name = parse_name t
			link = parse_link t
			magnet = parse_magnet t
			uploader = "eztv"
			timestamp = parse_timestamp t
			size = MIN_SIZE + 1

			parsed_episode = ParsedEpisode.new(name, link, magnet, uploader, timestamp, size)

			next unless parsed_episode.is_valid?

			episode = parsed_episode.to_episode

			save_episode(episode) if episode.is_new?
			update_episode(episode) if episode.is_improvement?
		end
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
		el.css("a.epinfo").inner_text.gsub(NBSP, " ")
	end

	def parse_link(el)
		el.css("a.download_1").attr("href").value.gsub(NBSP, " ")
	end

	def parse_magnet(el)
		el.css("a[href^=magnet]").attr("href").value.gsub(NBSP, " ")
	end

	def parse_timestamp(el)
		time = el.css("td:nth-child(4)").inner_text.gsub(NBSP, " ")
		days = time.sub(/.*(^|[^0-9])([0-9][0-9]?)d.*/, "\\2")
		days = 0 if days =~ /[a-z]/i
		days = days.to_i
		hours = time.sub(/.*(^|[^0-9])([0-9][0-9]?)h.*/, "\\2")
		hours = 0 if hours =~ /[a-z]/i
		hours = hours.to_i
		minutes = time.sub(/.*(^|[^0-9])([0-9][0-9]?)m.*/, "\\2")
		minutes = 0 if minutes =~ /[a-z]/i
		minutes = minutes.to_i

		hours += days * 24
		minutes += hours * 60

		Chronic.parse("#{minutes} minutes ago")
	end
end
