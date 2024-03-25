require "mechanize"
require "parslet"
require "digest/md5"
require "relaton/index"
require "relaton_bib"
require "relaton_itu/version"
require "relaton_itu/util"
require "relaton_itu/document_type"
require "relaton_itu/pubid"
require "relaton_itu/itu_bibliography"
require "relaton_itu/data_fetcher"
require "relaton_itu/data_parser_r"

module RelatonItu
  class Error < StandardError; end

  # Returns hash of XML reammar
  # @return [String]
  def self.grammar_hash
    # gem_path = File.expand_path "..", __dir__
    # grammars_path = File.join gem_path, "grammars", "*"
    # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest RelatonItu::VERSION + RelatonBib::VERSION # grammars
  end
end
