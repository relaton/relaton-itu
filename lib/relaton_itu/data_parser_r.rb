module RelatonItu
  module DataParserR
    extend self

    #
    # Parse ITU-R document.
    #
    # @param [Mechanize::Page] doc mechanize page
    # @param [String] url document url
    # @param [String] type document type
    #
    # @return [RelatonItu::ItuBibliographicItem] bibliographic item
    #
    def parse(doc, url, type)
      RelatonItu::ItuBibliographicItem.new(
        docid: fetch_docid(doc), title: fetch_title(doc),
        abstract: fetch_abstract(doc), date: fetch_date(doc), language: ["en"],
        link: fetch_link(url), script: ["Latn"], docstatus: fetch_status(doc),
        type: "standard", doctype: fetch_doctype(type)
      )
    end

    # @param doc [Mechanize::Page]
    # @return [Araay<RelatonBib::DocumentIdentifier>]
    def fetch_docid(doc)
      # id = doc.at('//h3[.="Number"]/parent::td/following-sibling::td[2]').text # .match(/^[^\s\(]+/).to_s
      # %r{^(?<id1>[^\s\(\/]+(\/\d+)?)(\/(?<id2>\w+[^\s\(]+))?} =~ id
      id = doc.at('//div[@id="idDocSetPropertiesWebPart"]/h2').text.match(/^R-\w+-([^-]+(?:-\d{1,3})?)/)[1]
      [RelatonBib::DocumentIdentifier.new(type: "ITU", id: "ITU-R #{id}", primary: true)]
      # docid << RelatonBib::DocumentIdentifier.new(type: 'ITU', id: id2) if id2
      # docid
    end

    # @param doc [Mechanize::Page]
    # @return [Araay<RelatonBib::TypedTitleString>]
    def fetch_title(doc)
      content = doc.at('//h3[.="Title"]/parent::td/following-sibling::td[2]').text
      [RelatonBib::TypedTitleString.new(type: "main", content: content, language: "en", script: "Latn")]
    end

    # @param doc [Mechanize::Page]
    # @return [Array<RelatonBib::FormattedString>]
    def fetch_abstract(doc)
      doc.xpath('//h3[.="Observation"]/parent::td/following-sibling::td[2]').map do |a|
        c = a.text.strip
        RelatonBib::FormattedString.new content: c, language: "en", script: "Latn" unless c.empty?
      end.compact
    end

    # @param doc [Mechanize::Page]
    # @return [Araay<RelatonBib::BibliographicDate>]
    def fetch_date(doc)
      dates = []
      date = doc.at('//h3[.="Approval_Date"]/parent::td/following-sibling::td[2]',
                    '//h3[.="Approval date"]/parent::td/following-sibling::td[2]',
                    '//h3[.="Approval year"]/parent::td/following-sibling::td[2]')
      dates << parse_date(date.text, "confirmed") if date

      date = doc.at('//h3[.="Version year"]/parent::td/following-sibling::td[2]')
      dates << parse_date(date.text, "updated") if date
      date = doc.at('//div[@id="idDocSetPropertiesWebPart"]/h2').text.match(/(?<=-)(19|20)\d{2}/)
      dates << parse_date(date.to_s, "published") if date
      dates
    end

    # @param date [String]
    # @param type [String]
    # @return [RelatonBib::BibliographicDate]
    def parse_date(date, type)
      d = case date
          # when /^\d{4}$/ then date
          when /(\d{4})(\d{2})/ then "#{$1}-#{$2}"
          when %r{(\d{1,2})/(\d{1,2})/(\d{4})} then "#{$3}-#{$1}-#{$2}"
          else date
          end
      RelatonBib::BibliographicDate.new(type: type, on: d)
    end

    # @param url [String]
    # @return [Array<RelatonBib::TypedUri>]
    def fetch_link(url)
      [RelatonBib::TypedUri.new(type: "src", content: url)]
    end

    # @param doc [Mechanize::Page]
    # @return [RelatonBib::DocumentStatus, nil]
    def fetch_status(doc)
      s = doc.at('//h3[.="Status"]/parent::td/following-sibling::td[2]')
      return unless s

      RelatonBib::DocumentStatus.new stage: s.text
    end

    def fetch_doctype(type)
      DocumentType.new(type: type)
    end
  end
end
