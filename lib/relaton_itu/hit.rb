# frozen_string_literal: true

module RelatonItu
  # Hit.
  class Hit < RelatonBib::Hit
    # Parse page.
    # @return [RelatonItu::ItuBibliographicItem]
    def fetch
      @fetch ||= Scrapper.parse_page hit, hit_collection.gi_imp
    end
  end
end
