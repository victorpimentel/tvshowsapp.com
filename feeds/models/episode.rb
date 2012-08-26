require "rubygems"
require "active_record"
require "models/uploader.rb"

class Episode < ActiveRecord::Base
	belongs_to :show
	attr_accessor :previous_episode_cached

	def is_new?
		!previous_episode
	end

	def is_improvement?
		previous = previous_episode
		if previous
			Uploader.new(self.uploader).is_better_than?(previous.uploader, self.show.uploader.split("|"))
		else
			false
		end
	end

	def previous_episode
		return self.previous_episode_cached if self.previous_episode_cached != nil
		self.previous_episode_cached = (Episode.find_by_show_id_and_number_and_version(self.show, self.number, self.version) || false)
	end

	def save_as_improvement
		previous_episode.link = self.link
		previous_episode.magnet = self.magnet
		previous_episode.uploader = self.uploader
		previous_episode.timestamp = self.timestamp
		previous_episode.save
	end

	def name
		if self.version == "hd"
			"#{self.show.name} #{self.number} 720p"
		else
			"#{self.show.name} #{self.number}"
		end
	end

	def direct_link
		if self.link =~ /^http.*/
			self.link
		else
			"http://torrents.thepiratebay.se/#{self.link}.torrent"
		end
	end

	def to_s
		"Show: #{self.show.name}\nNumber: #{self.number}\nVersion: #{self.version}\nLink: #{self.link}\nMagnet: #{self.magnet}\nUploader: #{self.uploader}\nUpdated at: #{self.timestamp}\n\n"
	end
end
