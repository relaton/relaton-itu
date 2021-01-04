module RelatonItu
  class ItuBibliographicItem < RelatonBib::BibliographicItem
    TYPES = %w[
      recommendation recommendation-supplement recommendation-amendment
      recommendation-corrigendum recommendation-errata recommendation-annex
      focus-group implementers-guide technical-paper technical-report
      joint-itu-iso-iec resolution service-publication handbook question
    ].freeze

    # @params structuredidentifier [RelatonItu::StructuredIdentifier]
    def initialize(**args)
      if args[:doctype] && !TYPES.include?(args[:doctype])
        warn "[relaton-itu] WARNING: invalid doctype: #{args[:doctype]}"
      end
      super
    end
  end
end
