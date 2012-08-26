#!/usr/bin/env ruby

require "rubygems"
require "active_record"
require "logger"
require "nokogiri"

MY_PATH = "/home/victorpimentel/tvshowsapp.com/feeds/"

ActiveRecord::Base.logger = Logger.new(MY_PATH + 'log/db.log')
ActiveRecord::Base.configurations = YAML::load_file(MY_PATH + 'config/database.yml')
ActiveRecord::Base.establish_connection('development')

LOGGER = Logger.new(MY_PATH + 'log/app.log')

config = YAML::load_file(MY_PATH + 'config/app_constants.yml')

VALID_UPLOADERS = config['valid_uploaders']
MIN_SIZE = config['min_size']

TPB_GENERIC_SEARCH_SD = config['tpb_generic_search_sd']
TPB_GENERIC_SEARCH_HD = config['tpb_generic_search_hd']
EZTV_GENERIC_SEARCH = config['eztv_generic_search']

TPB_SEARCH = config['tpb_search']
TERM_PLACEHOLDER = config['term_placeholder']
TPB_USER_AGENT = config['tpb_user_agent']

TVDB_SEARCH = config['tvdb_search']
TVDB_DETAILS = config['tvdb_details']
NAME_PLACEHOLDER = config['name_placeholder']
ID_PLACEHOLDER = config['id_placeholder']

SHOWLIST_FILE = config['showlist_file']
FEED_URL = config['feed_url']

DEBUG = config['debug']

INFINITY = 1.0/0
NBSP = Nokogiri::HTML("&nbsp;").text
