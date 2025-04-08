require "nokogiri"

module RelatonItu
  class XMLParser < RelatonBib::XMLParser
    class << self
      private

      # @param item_hash [Hash]
      # @return [RelatonItu::ItuBibliographicItem]
      def bib_item(item_hash)
        ItuBibliographicItem.new(**item_hash)
      end

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonItu::EditorialGroup]
      def fetch_editorialgroup(ext)
        return unless ext && (eg = ext.at "editorialgroup")

        EditorialGroup.new(
          bureau: eg.at("bureau")&.text,
          group: itugroup(eg.at("group")),
          subgroup: itugroup(eg.at("subgroup")),
          workgroup: itugroup(eg.at("workgroup")),
        )
      end

      # @param com [Nokogiri::XML::Element]
      # @return [RelatonItu::ItuGroup]
      def itugroup(group)
        return unless group

        ItuGroup.new(
          type: group[:type],
          name: group.at("name").text,
          acronym: group.at("acronym")&.text,
          period: itugroupperiod(group.at("period")),
        )
      end

      # @param com [Nokogiri::XML::Element]
      # @return [RelatonItu::ItuGroup::Period]
      def itugroupperiod(period)
        return until period

        ItuGroup::Period.new(
          start: period.at("start").text, finish: period.at("end")&.text,
        )
      end

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonItu::StructuredIdentifier]
      def fetch_structuredidentifier(ext)
        return unless ext && (sid = ext.at "./structuredidentifier")

        br = sid.at("bureau").text
        dn = sid.at("docnumber").text
        an = sid.at("annexid")&.text
        StructuredIdentifier.new(bureau: br, docnumber: dn, annexid: an)
      end

      def create_doctype(type)
        DocumentType.new type: type.text, abbreviation: type[:abbreviation]
      end
    end
  end
end
