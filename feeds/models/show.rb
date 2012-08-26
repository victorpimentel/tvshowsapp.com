require "rubygems"
require "active_record"
require "models/uploader.rb"
#require "models/search_term.rb"

class Show < ActiveRecord::Base
	has_many :episodes
	#has_many :search_terms

	def has_episode(episode)
		#matches_any_search_term(episode.name) and matches_any_uploader(episode.uploader)
		has_episode = (episode.name =~ search_regex)

		episode.name.gsub(/\.\-_/, " ").squeeze(" ").split(" ").each { |w|
			has_episode = false if filters_array.include? w.downcase
		}

		has_episode = false if !(Uploader.new(episode.uploader).is_valid? self.uploader.split("|"))

		has_episode
	end

	def matches_any_search_term?(episode_name)
		self.search_terms.any? {|term| term.matched_by? episode_name}
	end

	def matches_any_uploader?(episode_uploader)
		Uploader.new(episode.uploader).is_valid? self.uploader.split("|")
	end

	def filters_array
		self.search.split(" ").select{|s| s =~ /^\-/}.map{|s| s.sub(/^\-/, "").downcase}
	end

	def search_regex
		Regexp.new(self.search.sub(/\s20[0-9]{2}/, " ").split(" ").select{|s| s =~ /^[^\-]/}.join("(.{1,6})") + "[auks \-\.:0-9\(\)]+[0-9].*[0-9]", true)
	end

	def feed_url
		FEED_URL.sub(TERM_PLACEHOLDER, self.search.gsub(/\s/, "%20"))
	end

	def to_s
		"Name: #{self.name}, TVDB ID: #{self.tvdb_id}, Search term: #{self.search}, Uploader: #{self.uploader}, Status: #{self.status}"
	end
end
