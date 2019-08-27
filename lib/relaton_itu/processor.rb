require "relaton/processor"

module RelatonItu
  class Processor < Relaton::Processor
    def initialize
      @short = :relaton_itu
      @prefix = "ITU"
      @defaultprefix = %r{^(ITU)}
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
      item_hash = ::RelatonItu::HashConverter.hash_to_bib(hash)
      ::RelatonItu::ItuBibliographicItem.new item_hash
    end
  end
end
