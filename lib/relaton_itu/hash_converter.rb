module RelatonItu
  module HashConverter
    include RelatonBib::HashConverter
    extend self

    private

    #
    # Ovverides superclass's method
    #
    # @param item [Hash]
    # @retirn [RelatonItu::ItuBibliographicItem]
    def bib_item(item)
      ItuBibliographicItem.new(**item)
    end

    def editorialgroup_hash_to_bib(ret)
      eg = ret.dig(:ext, :editorialgroup) || ret[:editorialgroup] # @TODO: remove ret[:editorialgroup] after all gems will be updated
      return unless eg

      ret[:editorialgroup] = EditorialGroup.new(**eg)
    end

    # @param ret [Hash]
    def structuredidentifier_hash_to_bib(ret)
      struct_id = ret.dig(:ext, :structuredidentifier) || ret[:structuredidentifier] # @TODO: remove ret[:structuredidentifier] after all gems will be updated
      return unless struct_id

      ret[:structuredidentifier] = StructuredIdentifier.new(**struct_id)
    end

    def create_doctype(**args)
      DocumentType.new(**args)
    end
  end
end
