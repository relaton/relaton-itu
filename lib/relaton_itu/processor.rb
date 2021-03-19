require "relaton/processor"

module RelatonItu
  class Processor < Relaton::Processor
    def initialize
      @short = :relaton_itu
      @prefix = "ITU"
      @defaultprefix = %r{^ITU\s}
      @idtype = "ITU"
    end

    # @param code [String]
    # @param date [String, NilClass] year
    # @param opts [Hash]
    # @return [RelatonItu::ItuBibliographicItem]
    def get(code, date, opts)
      ::RelatonItu::ItuBibliography.get(code, date, opts)
    end

    # @param xml [String]
    # @return [RelatonItu::ItuBibliographicItem]
    def from_xml(xml)
      ::RelatonItu::XMLParser.from_xml xml
    end

    # @param hash [Hash]
    # @return [RelatonItu::ItuBibliographicItem]
    def hash_to_bib(hash)
      ::RelatonItu::ItuBibliographicItem.from_hash hash
    end

    # Returns hash of XML grammar
    # @return [String]
    def grammar_hash
      @grammar_hash ||= ::RelatonItu.grammar_hash
    end
  end
end
