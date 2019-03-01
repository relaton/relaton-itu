require "relaton/processor"

module Relaton
  module ItuBib
    class Processor < Relaton::Processor

      def initialize
        @short = :itubib
        @prefix = "ITU"
        @defaultprefix = %r{^(ITU)}
        @idtype = "ITU"
      end

      def get(code, date, opts)
        ::ItuBib::ItuBliography.get(code, date, opts)
      end

      def from_xml(xml)
        IsoBibItem::XMLParser.from_xml xml
      end
    end
  end
end
