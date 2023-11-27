module RelatonItu
  class ItuBibliographicItem < RelatonBib::BibliographicItem
    # @params structuredidentifier [RelatonItu::StructuredIdentifier]
    # def initialize(**args)
    #   super
    # end

    #
    # Fetch flavor schema version
    #
    # @return [String] flavor schema version
    #
    def ext_schema
      @ext_schema ||= schema_versions["relaton-model-itu"]
    end

    # @param hash [Hash]
    # @return [RelatonItu::ItuBibliographicItem]
    def self.from_hash(hash)
      item_hash = ::RelatonItu::HashConverter.hash_to_bib(hash)
      new(**item_hash)
    end
  end
end
