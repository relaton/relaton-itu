module RelatonItu
  class DocumentType < RelatonBib::DocumentType
    TYPES = %w[
      recommendation recommendation-supplement recommendation-amendment recommendation-corrigendum
      recommendation-errata recommendation-annex focus-group implementers-guide technical-paper
      technical-report joint-itu-iso-iec resolution service-publication handbook question contribution
    ].freeze

    def initialize(type:, abbreviation: nil)
      check_type type
      super
    end

    def check_type(type)
      unless TYPES.include? type
        Util.warn "Invalid doctype: `#{type}`"
      end
    end
  end
end
