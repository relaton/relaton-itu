require "relaton/processor"

module Relaton
  module RelatonItu
    class Processor < Relaton::Processor

      def initialize
        @short = :relaton_ite
        @prefix = "ITU"
        @defaultprefix = %r{^(ITU)}
        @idtype = "ITU"
      end

      def get(code, date, opts)
        ::RelatonItu::ItuBliography.get(code, date, opts)
      end

      def from_xml(xml)
        RelatonItu::XMLParser.from_xml xml
      end
    end
  end
end
