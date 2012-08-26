require "models/show.rb"
require "models/episode.rb"

class ParsedEpisode
	attr_accessor :name, :link, :magnet, :uploader, :timestamp, :size, :show_cached

	def initialize(name, link, magnet, uploader, timestamp, size)
		self.name = name
		self.link = link
		self.magnet = magnet
		self.uploader = uploader
		self.timestamp = timestamp
		self.size = size
	end

	def is_valid?
		is_size_valid? && is_name_valid? && show
	end

	def is_size_valid?
		self.size > MIN_SIZE
	end

	def is_name_valid?
		is_episodic? && !(self.name.downcase =~ /mindthe/)
	end

	def is_episodic?
		is_normal? || is_daily? || is_manga?
	end

	def is_normal?
		self.name =~ /[sS]?[0-9][0-9]?[eExX][0-9][0-9]?([\.\s\-]|$)/
	end

	def is_daily?
		self.name =~ /[0-9]{2,4}.[0-9]{2}.[0-9]{2,4}([\.\s]|$)/
	end

	def is_manga?
		self.name =~ /[^0-9xX][0-9]{3}([^0-9pP]|$)/
	end

	def is_hd?
		self.name =~ /720[pP]/
	end

	def version
		is_hd? ? "hd" : "sd"
	end

	def clean_name
		name = self.name.upcase + " "
		name = name.gsub(/[&_\/\.]/, " ").gsub(/(\s\-|\-\s)/, " ").gsub(/\s+/, " ").gsub(/\sAND\s/, " ")

		if is_normal?
			name = name.sub(/\sS?([1-9])[XE]([1-9])[^0-9].*/, " S0\\1E0\\2")
			name = name.sub(/\sS?([1-9])[XE]([0-9][0-9]).*/, " S0\\1E\\2")
			name = name.sub(/\sS?([0-9][0-9])[XE]([1-9])[^0-9].*/, " S\\1E0\\2")
			name = name.sub(/\sS?([0-9][0-9])[XE]([0-9][0-9]).*/, " S\\1E\\2")
		elsif is_daily?
			name = name.sub(/\s([0-9]{4}).([0-9]{2}).([0-9]{2}).*/, " \\1 \\2 \\3")
			name = name.sub(/\s([0-9]{2}).([0-9]{2}).([0-9]{4}).*/, " \\3 \\2 \\1")
			name = name.sub(/\s([0-9]{2}).([0-9]{2}).([0-9]{2}).*/, " 20\\3 \\2 \\1")
		elsif is_manga?
			name = name.sub(/([^0-9X])([0-9])([0-9][0-9])[^0-9P].*/, "\\1S0\\2E\\3")
		end

		name += " HD" if is_hd?

		name.strip
	end

	def show_name
		clean_name.sub(/\s(S[0-9]{2}|[0-9]{4}).*/, "")
	end

	def show
		return self.show_cached if self.show_cached != nil

		show = false
		Show.find(:all, :conditions => ["search LIKE ?", show_name + "%"]).each { |s|
			if s.has_episode(self)
				show = s
				break
			end
		}

		self.show_cached = show
	end

	def number
		clean_name.sub(/.*(S[0-9]{2}|[0-9]{4})/, "\\1").sub(/ HD/, "")
	end

	def to_episode
		Episode.new(
			:show => self.show,
			:number => self.number,
			:version => self.version,
			:link => self.link,
			:magnet => self.magnet,
			:uploader => self.uploader,
			:timestamp => self.timestamp
		)
	end

	def to_s
		puts "Name: #{self.name}"
		puts "Clean name: #{clean_name}"
		puts "Show name: #{show_name}"
		puts "Show: #{show}"
		puts "Number: #{number}"
		puts "Version: #{is_hd? ? "hd" : "sd"}"
		puts "Link: #{self.link}"
		puts "Magnet: #{self.magnet}"
		puts "Uploader: #{self.uploader}"
		puts "Timestamp: #{self.timestamp}"
		puts "Size: #{self.size}"
		puts ""
	end
end
