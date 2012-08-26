require "rubygems"
require "active_record"
require "models/uploader.rb"
require "models/show.rb"

class SearchTerm < ActiveRecord::Base
	belongs_to :show

	def matched_by?(episode_name)
		matches_regex?(episode_name) and contains_all_words?(episode_name)
	end

	def matches_regex?(episode_name)
		episode_name =~ search_regex
	end

	def search_regex
		Regexp.new(self.term.sub(/\s20[0-9]{2}/, " ").split(" ").select{|s| s =~ /^[^\-]/}.join("(.{1,6})") + "[auks \-\.:0-9\(\)]+[0-9].*[0-9]", true)
	end

	def contains_all_words?(episode_name)
		episode_name.gsub(/\.\-_/, " ").squeeze(" ").split(" ").all? do |w|
			term_words.include? w.downcase
		end
	end

	def term_words
		self.term.split(" ").select{|s| s =~ /^\-/}.map{|s| s.sub(/^\-/, "").downcase}
	end
end
