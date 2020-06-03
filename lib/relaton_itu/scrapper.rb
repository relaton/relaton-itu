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
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

      # Parse page.
      # @param hit_data [Hash]
      # @return [Hash]
      def parse_page(hit_data, imp = false)
        url, doc = get_page hit_data[:url]
        if imp
          a = doc.at "//span[contains(@id, 'tab_ig_uc_rec')]/a"
          return unless a

          url, doc = get_page URI.join(url, a[:href]).to_s
        end

        # Fetch edition.
        edition = doc.at("//table/tr/td/span[contains(@id, 'Label8')]/b")&.text

        ItuBibliographicItem.new(
          fetched: Date.today.to_s,
          docid: fetch_docid(doc),
          edition: edition,
          language: ["en"],
          script: ["Latn"],
          title: fetch_titles(doc),
          doctype: hit_data[:type],
          docstatus: fetch_status(doc),
          ics: [], # fetch_ics(doc),
          date: fetch_dates(doc),
          contributor: fetch_contributors(hit_data[:code]),
          editorialgroup: fetch_workgroup(hit_data[:code], doc),
          abstract: fetch_abstract(doc),
          copyright: fetch_copyright(hit_data[:code], doc),
          link: fetch_link(doc, url),
          relation: fetch_relations(doc),
          place: ["Geneva"],
        )
      end
      # rubocop:enable Metrics/AbcSize

      private

      # Fetch abstracts.
      # @param doc [Nokigiri::HTML::Document]
      # @return [Array<Array>]
      def fetch_abstract(doc)
        abstract_url = doc.at('//table/tr/td/span[contains(@id, "lbl_dms")]/div')
        return [] unless abstract_url

        url = abstract_url[:onclick].match(/https?[^']+/).to_s
        d = Nokogiri::HTML Net::HTTP.get(URI(url)).encode(undef: :replace, replace: "")
        abstract_content = d.css("p.MsoNormal").text.gsub(/\r\n/, "")
          .squeeze(" ").gsub(/\u00a0/, "")

        [{
          content: abstract_content,
          language: "en",
          script: "Latn",
        }]
      end

      # Get page.
      # @param path [String] page's path
      # @return [Array<String, Nokogiri::HTML::Document>]
      def get_page(url)
        uri = URI url
        resp = Net::HTTP.get_response(uri)
        until resp.code == "200"
          uri = URI resp["location"] if resp.code =~ /^30/
          resp = Net::HTTP.get_response(uri)
        end
        [uri.to_s, Nokogiri::HTML(resp.body)]
      rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
             EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
             Net::ProtocolError, OpenSSL::SSL::SSLError
        raise RelatonBib::RequestError, "Could not access #{url}"
      end
      # rubocop:enable Metrics/MethodLength

      # Fetch docid.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Hash]
      def fetch_docid(doc)
        doc.xpath(
          "//span[@id='ctl00_content_main_uc_rec_main_info1_rpt_main_ctl00_lbl_rec']",
          "//td[.='Identical standard:']/following-sibling::td",
          "//div/table[1]/tr[4]/td/strong",
        ).map do |code|
          id = code.text.match(%r{^.*?(?= \()|\w\.Imp\s?\d+}).to_s.squeeze(" ")
          type = id.match(%r{^\w+}).to_s
          type = "ITU" if type == "G"
          RelatonBib::DocumentIdentifier.new(type: type, id: id)
        end
      end

      # Fetch status.
      # @param doc [Nokogiri::HTML::Document]
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
      # @param doc [Nokogiri::HTML::Document]
      # @return [RelatonItu::EditorialGroup, NilClass]
      def fetch_workgroup(code, doc)
        wg = doc.at('//table/tr/td/span[contains(@id, "Label8")]/a')
        # return unless wg

        group = wg && itugroup(wg.text)
        EditorialGroup.new(
          bureau: code.match(/(?<=-)./).to_s,
          group: group,
        )
      end

      # @param name [String]
      # @return [RelatonItu::ItuGroup]
      def itugroup(name)
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

      # rubocop:disable Metrics/MethodLength

      # Fetch relations.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      def fetch_relations(doc)
        doc.xpath('//div[contains(@id, "tab_sup")]//table/tr[position()>2]').map do |r|
          ref = r.at('./td/span[contains(@id, "title_e")]/nobr/a')
          fref = RelatonBib::FormattedRef.new(content: ref.text, language: "en", script: "Latn")
          bibitem = RelatonIsoBib::IsoBibliographicItem.new(formattedref: fref)
          { type: "complements", bibitem: bibitem }
        end
      end
      # rubocop:enable Metrics/MethodLength

      # Fetch titles.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      def fetch_titles(doc)
        t = doc.at("//td[@class='title']|//div/table[1]/tr[4]/td/strong")
        return [] unless t

        titles = t.text.sub(/\w\.Imp\s?\d+\u00A0:\u00A0/, "").split " - "
        case titles.size
        when 0
          intro, main, part = nil, "", nil
        when 1
          intro, main, part = nil, titles[0], nil
        when 2
          if /^(Part|Partie) \d+:/ =~ titles[1]
            intro, main, part = nil, titles[0], titles[1]
          else
            intro, main, part = titles[0], titles[1], nil
          end
        when 3
          intro, main, part = titles[0], titles[1], titles[2]
        else
          intro, main, part = titles[0], titles[1], titles[2..-1]&.join(" -- ")
        end
        [{
          title_intro: intro,
          title_main: main,
          title_part: part,
          language: "en",
          script: "Latn",
        }]
      end

      # Fetch dates
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      def fetch_dates(doc)
        dates = []
        date = doc.at("//table/tr/td/span[contains(@id, 'Label5')]",
                      "//p[contains(.,'Approved in')]")
        pdate = date&.text&.match(/\d{4}-\d{2}-\d{2}/).to_s || ob_date(doc)
        if pdate && !pdate&.empty?
          dates << { type: "published", on: pdate }
        end
        dates
      end

      # Scrape Operational Bulletin date.
      # @param doc [Nokogiri::HTML::Document]
      # @return [String]
      def ob_date(doc)
        pdate = doc.at('//table/tbody/tr/td[contains(text(), "Year:")]')
        return unless pdate

        roman_to_arabic pdate.text.match(%r{(?<=Year: )\d{2}.\w+.\d{4}}).to_s
      end

      # Convert roman month number in string date to arabic number
      # @param date [String]
      # @return [String]
      def roman_to_arabic(date)
        %r{(?<rmonth>[IVX]+)} =~ date
        month = ROMAN_MONTHS.index(rmonth) + 1
        Date.parse(date.sub(%r{[IVX]+}, month.to_s)).to_s
      end

      # Fetch contributors
      # @param doc [Nokogiri::HTML::Document]
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
      # @param doc [Nokogiri::HTML::Document]
      # @param url [String]
      # @return [Array<Hash>]
      def fetch_link(doc, url)
        links = [{ type: "src", content: url }]
        obp_elm = doc.at(
          '//a[@title="Persistent link to download the PDF file"]',
          "//font[contains(.,'PDF')]/../..",
        )
        links << typed_link("obp", obp_elm) if obp_elm
        wrd_elm = doc.at("//font[contains(.,'Word')]/../..")
        links << typed_link("word", wrd_elm) if wrd_elm
        links
      end

      def typed_link(type, elm)
        {
          type: type,
          content: URI.join(HitCollection::DOMAIN + elm[:href].strip).to_s,
        }
      end

      # Fetch copyright.
      # @param code [String]
      # @param doc [Nokogiri::HTML::Document]
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
