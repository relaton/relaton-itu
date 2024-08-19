# frozen_string_literal: true

require "nokogiri"
require "net/http"

module RelatonItu
  # Scrapper.
  module Scrapper
    ROMAN_MONTHS = %w[I II III IV V VI VII VIII IX X XI XII].freeze

    TYPES = {
      "ISO" => "international-standard",
      "TS" => "technicalSpecification",
      "TR" => "technicalReport",
      "PAS" => "publiclyAvailableSpecification",
      "AWI" => "appruvedWorkItem",
      "CD" => "committeeDraft",
      "FDIS" => "finalDraftInternationalStandard",
      "NP" => "newProposal",
      "DIS" => "draftInternationalStandard",
      "WD" => "workingDraft",
      "R" => "recommendation",
      "Guide" => "guide",
    }.freeze

    class << self
      # Parse page.
      # @param hit [RelatonItu::Hit]
      # @return [Hash]
      def parse_page(hit, imp: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        doc = get_page hit
        return unless doc.code == "200"

        if imp
          a = doc.at "//span[contains(@id, 'tab_ig_uc_rec')]/a"
          return unless a

          doc = get_page hit, a[:href].to_s
        end

        # Fetch edition.
        edition = doc.at("//table/tr/td[contains(@style,'color: white')]/span[contains(@id, 'Label8')]/b")&.text
        docid = fetch_docid(doc, hit)

        ItuBibliographicItem.new(
          id: fetch_id(docid),
          fetched: Date.today.to_s,
          type: "standard",
          docid: docid,
          edition: edition,
          language: ["en"],
          script: ["Latn"],
          title: fetch_titles(doc),
          doctype: DocumentType.new(type: hit.hit[:type]),
          docstatus: fetch_status(doc),
          ics: [], # fetch_ics(doc),
          date: fetch_dates(doc),
          contributor: fetch_contributors(hit.hit[:code]),
          editorialgroup: fetch_workgroup(hit.hit[:code], doc),
          abstract: fetch_abstract(doc, hit),
          copyright: fetch_copyright(hit.hit[:code], doc),
          link: fetch_link(doc),
          relation: fetch_relations(doc),
          place: ["Geneva"],
        )
      end

      private

      def fetch_id(docid)
        docid.find(&:primary).id.gsub(/[.\s()\/-]/, "")
      end

      # Fetch abstracts.
      # @param doc [Mechanize::Page]
      # @param hit [RelatonItu::Hit]
      # @return [Array<Hash>]
      def fetch_abstract(doc, hit) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        abstract_url = doc.at '//table/tr/td[contains(@style,"color: white")]/span[contains(@id, "lbl_dms")]/div'
        if abstract_url
          url = abstract_url[:onclick].match(/https?[^']+/).to_s
          rsp = hit.hit_collection.agent.get url
          d = Nokogiri::HTML rsp.body.encode(undef: :replace, replace: "")
          d.css("p.MsoNormal").text.gsub("\r\n", "").squeeze(" ").gsub("\u00a0", "")
        elsif a = doc.at('//table/tr/td/span[contains(@class, "observation")]/text()')
          a.text.strip
        end => content
        return [] unless content

        [{
          content: content,
          language: "en",
          script: "Latn",
        }]
      rescue Mechanize::ResponseCodeError => e
        Util.error "HTTP Service Unavailable: #{e.message}"
        []
      end

      # Get page.
      # @param hit [RelatonItu::Hit]
      # @param url [String, nil]
      # @return [Array<String, Nokogiri::HTML::Document>]
      def get_page(hit, url = nil)
        uri = url || hit.hit[:url]
        hit.hit_collection.agent.get uri
      rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
             EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
             Net::ProtocolError, OpenSSL::SSL::SSLError
        raise RelatonBib::RequestError, "Could not access #{uri}"
      end

      # Fetch docid.
      # @param doc [Mechanize::Page]
      # @param hit [RelatonItu::Hit]
      # @return [Hash]
      def fetch_docid(doc, hit)
        docids = hit.hit[:code].to_s.split(" | ").map { |c| createdocid(c) }
        docids += parse_id(doc).map { |c| createdocid c.text } if docids.empty?
        docids << createdocid(title) unless docids.any?
        docids
      end

      def parse_id(doc)
        doc.xpath(
          "//span[@id='ctl00_content_main_uc_rec_main_info1_rpt_main_ctl00_lbl_rec']",
          "//td[.='Identical standard:']/following-sibling::td",
          "//div/table[1]/tr[4]/td/strong",
        )
      end

      # @param text [String]
      # @return [RelatonBib::DocumentIdentifier]
      def createdocid(text) # rubocop:disable Metrics/MethodLength
        # %r{
        #   ^(?<code>(?:(?:ITU-\w|ISO/IEC)\s)?[^(:]*)
        #   (?:\s\(V(?<version>\d+)\))?
        #   (?:\s\((?:(?<_month>\d{2})/)?(?<_year>\d{4})\))?
        #   (?::[^(]+\((?<buldate>\d{2}\.\w{1,4}\.\d{4})\))?
        #   (?:\s(?<corr>(?:Amd|Cor)\.\s?\d+))?
        #   # (\s\(((?<_cormonth>\d{2})\/)?(?<_coryear>\d{4})\))?
        # }x =~ text.squeeze(" ")
        # corr&.sub!(/\.\s?/, " ")
        # id = [code.sub(/[[:space:]]$/, ""), corr].compact.join " "
        # id += " (V#{version})" if version
        # id += " - #{buldate}" if buldate
        # type = id.match(%r{^\w+}).to_s
        # type = "ITU" if type == "G"
        if text.match?(/^(?:ISO|ETSI)/)
          type = "ISO"
          text.match(/[^(]+/).to_s.strip.squeeze(" ")
        else
          pubid = Pubid.parse(text)
          type = pubid.prefix # == "G" ? "ITU" : pubid.prefix
          pubid.to_s
        end => id
        RelatonBib::DocumentIdentifier.new(type: type, id: id, primary: true)
      end

      # Fetch status.
      # @param doc [Mechanize::Page]
      # @return [RelatonBib::DocumentStatus, NilClass]
      def fetch_status(doc)
        s = doc.at("//table/tr/td/span[contains(@id, 'Label7')]",
                   "//p[contains(.,'Status :')]")
        return unless s

        status = s.text.include?("In force") ? "Published" : "Withdrawal"
        RelatonBib::DocumentStatus.new(stage: status)
      end

      # Fetch workgroup.
      # @param code [String]
      # @param doc [Mechanize::Page]
      # @return [RelatonItu::EditorialGroup, NilClass]
      def fetch_workgroup(code, doc)
        wg = doc.at('//table/tr/td/span[contains(@id, "Label8")]/a')
        # return unless wg

        group = wg && itugroup(wg.text)
        EditorialGroup.new(
          bureau: code.match(/(?<=-)./).to_s, group: group
        )
      end

      # @param name [String]
      # @return [RelatonItu::ItuGroup]
      def itugroup(name) # rubocop:disable Metrics/MethodLength
        if name.include? "Study Group"
          type = "study-group"
          acronym = "SG"
        elsif name.include? "Telecommunication Standardization Advisory Group"
          type = "tsag"
          acronym = "TSAG"
        else
          type = "work-group"
          acronym = "WG"
        end
        ItuGroup.new name: name, type: type, acronym: acronym
      end

      # Fetch relations.
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_relations(doc)
        doc.xpath('//div[contains(@id, "tab_sup")]//table/tr[position()>2]')
          .map do |r|
          ref = r.at('./td/span[contains(@id, "title_e")]/nobr/a')
          fref = RelatonBib::FormattedRef.new(content: ref.text, language: "en",
                                              script: "Latn")
          did = RelatonBib::DocumentIdentifier.new(id: ref.text, type: "ITU")
          bibitem = ItuBibliographicItem.new(formattedref: fref, docid: [did],
                                             type: "standard")
          { type: "complementOf", bibitem: bibitem }
        end
      end

      # Fetch titles.
      # @param doc [Mechanize::Page]
      # @return [RelatonBib::TypedTitleStringCollection]
      def fetch_titles(doc)
        t = doc.at("//td[@class='title']|//div/table[1]/tr[4]/td/strong")
        return [] unless t

        RelatonBib::TypedTitleString.from_string t.text, "en", "Latn"
      end

      # Fetch dates
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_dates(doc) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        dates = []
        date = doc.at("//table/tr/td/span[contains(@id, 'Label5')]",
                      "//p[contains(.,'Approved in')]")
        pdate = date&.text&.match(/\d{4}-\d{2}-\d{2}/).to_s || ob_date(doc)
        if pdate && !pdate&.empty?
          dates << { type: "published", on: pdate }
        elsif pdate = ob_date(doc)
          dates << { type: "published", on: pdate }
        end
        dates
      end

      # Scrape Operational Bulletin date.
      # @param doc [Mechanize::Page]
      # @return [String]
      def ob_date(doc)
        pdate = doc.at('//table/tbody/tr/td[contains(text(), "Year:")]')
        return unless pdate

        roman_to_arabic pdate.text.match(%r{(?<=Year: )(\d{2}.\w+.)?\d{4}}).to_s
      end

      # Convert roman month number in string date to arabic number
      # @param date [String]
      # @return [String]
      def roman_to_arabic(date)
        %r{(?<rmonth>[IVX]+)} =~ date
        if ROMAN_MONTHS.index(rmonth)
          month = ROMAN_MONTHS.index(rmonth) + 1
          Date.parse(date.sub(%r{[IVX]+}, month.to_s)).to_s
        else date
        end
      end

      # Fetch contributors
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_contributors(code)
        return [] unless code

        abbrev = code.sub(/-\w\s.*/, "")
        case abbrev
        when "ITU"
          name = "International Telecommunication Union"
          url = "www.itu.int"
        end
        [{ entity: { name: name, url: url, abbreviation: abbrev },
           role: [type: "publisher"] }]
      end

      # Fetch links.
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_link(doc)
        links = [{ type: "src", content: doc.uri.to_s }]
        obp_elm = doc.at(
          '//a[@title="Persistent link to download the PDF file"]',
          "//font[contains(.,'PDF')]/../..",
        )
        links << typed_link("obp", obp_elm) if obp_elm
        wrd_elm = doc.at("//font[contains(.,'Word')]/../..")
        links << typed_link("word", wrd_elm) if wrd_elm
        links
      end

      # @param type [String]
      # @param elm [Nokogiri::XML::Element]
      def typed_link(type, elm)
        {
          type: type,
          content: URI.join(HitCollection::DOMAIN, elm[:href].strip).to_s,
        }
      end

      # Fetch copyright.
      # @param code [String]
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_copyright(code, doc)
        abbreviation = code.match(/^[^-]+/).to_s
        case abbreviation
        when "ITU"
          name = "International Telecommunication Union"
          url = "www.itu.int"
        end
        fdate = doc.at("//table/tr/td/span[contains(@id, 'Label5')]")
        from = fdate&.text || ob_date(doc)
        [{ owner: [{ name: name, abbreviation: abbreviation, url: url }],
           from: from }]
      end
    end
  end
end
