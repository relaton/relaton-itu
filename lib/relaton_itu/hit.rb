# frozen_string_literal: true

module RelatonItu
  # Hit.
  class Hit < RelatonBib::Hit
    attr_writer :fetch

    # Parse page.
    # @return [RelatonItu::ItuBibliographicItem]
    def fetch
      @fetch ||= Scrapper.parse_page self, imp: hit_collection.gi_imp
    end
  end
end
