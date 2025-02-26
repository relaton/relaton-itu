module Relaton
  module Itu
    class Doctype < Bib::Doctype
      TYPES = %w[
        recommendation recommendation-supplement recommendation-amendment recommendation-corrigendum
        recommendation-errata recommendation-annex focus-group implementers-guide technical-paper
        technical-report joint-itu-iso-iec resolution service-publication handbook question contribution
      ].freeze

      attribute :type, :string, values: TYPES
    end
  end
end
