#!/usr/bin/env ruby

require "rubygems"
require "builder"

require "app.rb"
require "models/show.rb"
require "models/episode.rb"

class FeedGenerator
	def generate(show)
		xml = Builder::XmlMarkup.new(:indent => DEBUG ? 1 : 0)

		# Insert the required processing instruction
		xml.instruct! :xml, :version => "1.0"

		# Dump the episodes list
		xml.rss :version => "2.0" do
			xml.channel do
				xml.title show.name
				xml.description "Episodes for #{show.name}"
				xml.pubDate DateTime.now.to_s(:rfc822)
				xml.link show.feed_url

				Episode.limit(10).order("number DESC").find_all_by_show_id(show.id).each do |episode|
					xml.item do
						xml.title episode.name
						xml.description episode.uploader
						xml.pubDate episode.timestamp.to_s(:rfc822)
						xml.link episode.direct_link
						xml.guid episode.magnet, :isPermaLink => true
					end
				end
			end
		end

		# Dump it to the xml file
		File.open("#{MY_PATH}/cache/#{show.search}.xml","w") do |f|
			f.write(xml.target!)
		end
	end
end
