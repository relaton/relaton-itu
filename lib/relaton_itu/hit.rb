# frozen_string_literal: true

module RelatonItu
  # Hit.
  class Hit < RelatonBib::Hit
    # Parse page.
    # @return [Isobib::IsoBibliographicItem]
    def fetch
      @fetch ||= Scrapper.parse_page @hit
    end
  end
end
