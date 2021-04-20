module RelatonItu
  class HashConverter < RelatonBib::HashConverter
    class << self
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
        eg = ret[:editorialgroup]
        return unless eg

        ret[:editorialgroup] = EditorialGroup.new **eg
      end

      # @param ret [Hash]
      def structuredidentifier_hash_to_bib(ret)
        return unless ret[:structuredidentifier]

        ret[:structuredidentifier] = StructuredIdentifier.new(
          **ret[:structuredidentifier]
        )
      end
    end
  end
end
