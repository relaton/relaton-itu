module RelatonItu
  class ItuBibliographicItem < RelatonBib::BibliographicItem
    TYPES = %w[
      recommendation recommendation-supplement recommendation-amendment
      recommendation-corrigendum recommendation-errata recommendation-annex
      focus-group implementers-guide technical-paper technical-report
      joint-itu-iso-iec
    ].freeze

    # @params structuredidentifier [RelatonItu::StructuredIdentifier]
    def initialize(**args)
      # @doctype = args.delete :doctype
      if args[:doctype] && !TYPES.include?(args[:doctype])
        warn "[relaton-itu] WARNING: invalid doctype: #{args[:doctype]}"
      end
      super
      # @doctype = args[:doctype]
    end
  end
end
