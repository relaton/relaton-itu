module RelatonItu
  class ItuBibliographicItem < RelatonIsoBib::IsoBibliographicItem
    TYPES = %w[
      recommendation recommendation-supplement recommendation-amendment
      recommendation-corrigendum recommendation-errata recommendation-annex
      focus-group implementers-guide technical-paper technical-report
      joint-itu-iso-iec
    ].freeze

    # @params structuredidentifier [RelatonItu::StructuredIdentifier]
    def initialize(**args)
      @doctype = args.delete :doctype
      if doctype && !TYPES.include?(doctype)
        warn "[relaton-itu] WARNING: invalid doctype: #{doctype}"
      end
      super
    end
  end
end
