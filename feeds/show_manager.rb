#!/usr/bin/env ruby
$LOAD_PATH << '/home/victorpimentel/tvshowsapp.com/feeds/'

require "rubygems"
require "open-uri"
require "nokogiri"
require 'thor'

require "app.rb"
require "models/show.rb"
require "episode_manager.rb"
require "feed_manager.rb"
require "showlist_generator.rb"

class ShowManager < Thor
	include Thor::Actions

	desc "import_old_showlist [FILENAME]", "Import old shows from an old xml."
	def import_old_showlist(filename="../showlist/showlist.xml")
		begin
			# Parse the previous xml with the show list
			doc = Nokogiri::XML(open(filename))
			shows = doc.css("show")

			# Add each show...
			shows.each do |s|
				name = s.css("name").first.inner_text
				tvdb_id = s.css("tvdbid").first.inner_text.to_i
				search = s.css("mirror").first.inner_text.sub(/.*filter=(.*)&.*/, "\\1").gsub(/%20/, " ").gsub(/(eztv|vtv)/, "").gsub(/[^0-9a-zA-Z\-\s]/, "").squeeze(" ").strip
				uploader = ""
				s.css("mirror").each { |m|
					uploader += m.inner_text.sub(/.*userName=/, "").downcase + "|"
				}
				uploader.sub!(/\|$/, "")

				add_show(name, tvdb_id, search, uploader)
			end
		rescue Exception => e
			LOGGER.error e
		end
	end

	desc "add_show [NAME TVDB_ID SEARCH UPLOADER]", "Adds new show to the show list."
	method_option :interactive, :aliases => "-i", :desc => "Prompt for the values."
	def add_show(name = "", tvdb_id = 0, search = "", uploader = "")
		if options[:interactive]
			name = ask "Name:"

			guess_tvdb_id = guess_tvdb_id(name)
			if guess_tvdb_id
				tvdb_id = ask "TVDB ID [#{guess_tvdb_id}]:"
				if !tvdb_id || tvdb_id.length == 0
					tvdb_id = guess_tvdb_id
				end
			else
				tvdb_id = ask "TVDB ID:"
			end

			search = ask "Search [#{name}]:"
			if !search || search.length == 0
				search = name
			end

			default_uploader = "tvteam"
			uploader = ask "Uploader [#{default_uploader}]:"
			if !uploader || uploader.length == 0
				uploader = default_uploader
			end
		end

		return if name.length < 5 || tvdb_id == 0 || search.length < 5 || uploader.length < 3

		begin
			show = Show.new(
				:name => name,
				:tvdb_id => tvdb_id.to_i,
				:search => search,
				:uploader => uploader
			)

			if options[:interactive]
				puts show
				return unless yes? "Is this correct?"
			end

			show.save

			LOGGER.info "Added show #{show.name}."

			episode_manager = EpisodeManager.new
			episode_manager.populate show.id, show.id

			feed_manager = FeedManager.new
			feed_manager.generate_for_show show.search

			showlist_generator = ShowlistGenerator.new
			showlist_generator.dump_showlist
		rescue Exception => e
			LOGGER.error e
		end
	end

	desc "edit_show [OLD_NAME NEW_NAME TVDB_ID SEARCH UPLOADER]", "Edits a existing show in the show list."
	method_option :interactive, :aliases => "-i", :desc => "Prompt for the values."
	def edit_show(old_name = "", new_name = "", tvdb_id = 0, search = "", uploader = "")
		begin
			if options[:interactive]
				old_name = ask "Old name:"
			end

			return if old_name.length < 5
			show = Show.find_by_name(old_name)

			if options[:interactive]
				new_name = ask "New name [#{show.name}]:"
				tvdb_id = ask "TVDB ID [#{show.tvdb_id}]:"
				search = ask "Search [#{show.search}]:"
				uploader = ask "Uploader [#{show.uploader}]:"
			end

			if new_name && new_name.length > 4
				show.name = new_name
			end
			if tvdb_id && tvdb_id.to_i > 0
				show.tvdb_id = tvdb_id
			end
			if search && search.length > 4
				show.search = search
			end
			if uploader && uploader.length > 2
				show.uploader = uploader
			end

			if options[:interactive]
				puts show
				return unless yes? "Is this correct?"
			end

			show.save

			LOGGER.info "Edited show #{show.name}."

			episode_manager = EpisodeManager.new
			episode_manager.populate show.id, show.id

			feed_manager = FeedManager.new
			feed_manager.generate_for_show show.search

			showlist_generator = ShowlistGenerator.new
			showlist_generator.dump_showlist
		rescue Exception => e
			LOGGER.error e
		end
	end

	desc "end_show [NAME]", "Marks a existing show as ended."
	method_option :interactive, :aliases => "-i", :desc => "Prompt for the values."
	def end_show(name = "")
		begin
			if options[:interactive]
				name = ask "Old name:"
			end

			return if name.length < 5

			show = Show.find_by_name(name)
			show.status = "ended"

			if options[:interactive]
				puts show
				return unless yes? "Is this correct?"
			end

			show.save

			LOGGER.info "Ended show #{show.name}."

			showlist_generator = ShowlistGenerator.new
			showlist_generator.dump_showlist
		rescue Exception => e
			LOGGER.error e
		end
	end

	no_tasks do
		def guess_tvdb_id(name)
			clean_name = URI.escape(name).gsub("&", "%26")
			tvdb_search_url = TVDB_SEARCH.sub("{name}", clean_name)

			begin
				doc = Nokogiri::XML(open(tvdb_search_url))
			rescue Exception => e
				return nil
			end

			results = doc.css("id")

			return nil if !results.first

			tvdb_id = results.first.inner_text

			return tvdb_id
		end
	end

end

ShowManager.start if __FILE__ == $0
