require "relaton/processor"

module RelatonItu
  class Processor < Relaton::Processor
    def initialize
      @short = :relaton_itu
      @prefix = "ITU"
      @defaultprefix = %r{^ITU\s}
      @idtype = "ITU"
      @datasets = %w[itu-r]
    end

    # @param code [String]
    # @param date [String, NilClass] year
    # @param opts [Hash]
    # @return [RelatonItu::ItuBibliographicItem]
    def get(code, date, opts)
      ::RelatonItu::ItuBibliography.get(code, date, opts)
    end

    #
    # Fetch all the documents from https://extranet.itu.int/brdocsearch/
    #
    # @param [String] source source name (itu-r)
    # @param [Hash] opts
    # @option opts [String] :output directory to output documents, default is data
    # @option opts [String] :format output format, default is yaml
    #
    def fetch_data(_source, opts)
      DataFetcher.fetch(**opts)
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

    #
    # Remove index file
    #
    def remove_index_file
      Relaton::Index.find_or_create(:itu, url: true, file: HitCollection::INDEX_FILE).remove_file
    end
  end
end
