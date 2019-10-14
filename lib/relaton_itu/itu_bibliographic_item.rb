module RelatonItu
  class ItuBibliographicItem < RelatonIsoBib::IsoBibliographicItem
    TYPES = %w[
      recommendation recommendation-supplement recommendation-amendment
      recommendation-corrigendum recommendation-errata recommendation-annex
      focus-group implementers-guide technical-paper technical-report
      joint-itu-iso-iec
    ].freeze

    def initialize(**args)
      @doctype = args.delete :doctype
      if doctype && !TYPES.include?(doctype)
        raise ArgumentError, "invalid doctype: #{doctype}"
      end

      super
    end
  end
end
