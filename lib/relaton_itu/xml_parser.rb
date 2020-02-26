require "nokogiri"

module RelatonItu
  class XMLParser < RelatonIsoBib::XMLParser
    class << self
      # Override RelatonIsoBib::XMLParser.form_xml method.
      # @param xml [String]
      # @return [RelatonItu::ItuBibliographicItem]
      def from_xml(xml)
        doc = Nokogiri::XML(xml)
        ituitem = doc.at "/bibitem|/bibdata"
        if ituitem
          ItuBibliographicItem.new item_data(ituitem)
        elsif
          warn "[relato-itu] can't find bibitem or bibdata element in the XML"
        end
      end

      private

      # @param ext [Nokogiri::XML::Element]
      # @return [RelatonItu::EditorialGroup]
      def fetch_editorialgroup(ext)
        eg = ext.at("./editorialgroup")
        return unless eg

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
          acronym: group.at("acronym").text,
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
    end
  end
end
