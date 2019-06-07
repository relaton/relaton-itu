module RelatonItu
  class ItuBibliographicItem < RelatonIsoBib::IsoBibliographicItem
    TYPES = %w[
      recommendation recommendation-supplement recommendation-amendment
      recommendation-corrigendum recommendation-errata recommendation-annex
      focus-group implementers-guide technical-paper technical-report
      joint-itu-iso-iec
    ].freeze

    def initialize(**args)
      @doctype = args.delete :type
      if doctype && !TYPES.include?(doctype)
        raise ArgumentError, "invalid type: #{doctype}"
      end

      super
    end

    def to_xml(builder = nil, **opts)
      super builder, **opts do |b|
        if opts[:bibdata]
          # b.doctype doctype if doctype
        end
      end
    end
  end
end
