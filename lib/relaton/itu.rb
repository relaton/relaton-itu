require "mechanize"
require "parslet"
require "digest/md5"
require "relaton/index"
require "relaton/bib"
require_relative "itu/version"
require_relative "itu/util"
require_relative "itu/item"
require_relative "itu/bibitem"
require_relative "itu/bibdata"
# require "relaton_itu/document_type"
# require "relaton_itu/pubid"
# require "relaton_itu/itu_bibliography"
# require "relaton_itu/data_fetcher"
# require "relaton_itu/data_parser_r"

module Relaton
  module Itu
    class Error < StandardError; end

    # Returns hash of XML reammar
    # @return [String]
    def self.grammar_hash
      # gem_path = File.expand_path "..", __dir__
      # grammars_path = File.join gem_path, "grammars", "*"
      # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
      Digest::MD5.hexdigest Relaton::Itu::VERSION + Relaton::Bib::VERSION # grammars
    end
  end
end
