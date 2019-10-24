# frozen_string_literal: true

require "nokogiri"
require "net/http"

# Capybara.request_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new app, js_errors: false
# end
# Capybara.default_driver = :poltergeist

module RelatonItu
  # Scrapper.
  # rubocop:disable Metrics/ModuleLength
  module Scrapper
    DOMAIN = "https://www.itu.int"
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
      # @param text [String]
      # @return [Array<Hash>]
      # def get(text)
      #   iso_workers = WorkersPool.new 4
      #   iso_workers.worker { |hit| iso_worker(hit, iso_workers) }
      #   algolia_workers = start_algolia_search(text, iso_workers)
      #   iso_docs = iso_workers.result
      #   algolia_workers.end
      #   algolia_workers.result
      #   iso_docs
      # end

      # Parse page.
      # @param hit [Hash]
      # @return [Hash]
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def parse_page(hit_data)
        url, doc = get_page hit_data[:url]

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
          editorialgroup: fetch_workgroup(doc),
          abstract: fetch_abstract(doc),
          copyright: fetch_copyright(hit_data[:code], doc),
          link: fetch_link(doc, url),
          relation: fetch_relations(doc),
        )
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      private

      # Fetch abstracts.
      # @param doc [Nokigiri::HTML::Document]
      # @return [Array<Array>]
      def fetch_abstract(doc)
        abstract_url = doc.at('//table/tr/td/span[contains(@id, "lbl_dms")]/div')
        return [] unless abstract_url

        url = abstract_url[:onclick].match(/https?[^']+/).to_s
        d = Nokogiri::HTML Net::HTTP.get(URI(url))
        abstract_content = d.css("p.MsoNormal").text.gsub(/\r\n/, "")
          .gsub(/\s{2,}/, " ").gsub(/\u00a0/, "")

        [{
          content: abstract_content,
          language: "en",
          script: "Latn",
        }]
      end

      # Get langs.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      # def langs(doc)
      #   lgs = [{ lang: 'en' }]
      #   doc.css('ul#lang-switcher ul li a').each do |lang_link|
      #     lang_path = lang_link.attr('href')
      #     lang = lang_path.match(%r{^\/(fr)\/})
      #     lgs << { lang: lang[1], path: lang_path } if lang
      #   end
      #   lgs
      # end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # Get page.
      # @param path [String] page's path
      # @return [Array<Nokogiri::HTML::Document, String>]
      def get_page(url)
        uri = URI url
        resp = Net::HTTP.get_response(uri) # .encode("UTF-8")
        while resp.code == "301" || resp.code == "302" || resp.code == "303"
          uri = URI resp["location"]
          resp = Net::HTTP.get_response(uri) # .encode("UTF-8")
        end
        [uri.to_s, Nokogiri::HTML(resp.body)]
      rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
             Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
             OpenSSL::SSL::SSLError
        raise RelatonBib::RequestError, "Could not access #{url}"
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # Fetch docid.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Hash]
      def fetch_docid(doc)
        doc.xpath(
          "//span[@id='ctl00_content_main_uc_rec_main_info1_rpt_main_ctl00_lbl_rec']",
          "//td[.='Identical standard:']/following-sibling::td",
        ).map do |code|
          id = code.text.match(%r{^.*?(?= \()}).to_s.squeeze(" ")
          type = id.match(%r{^\w+}).to_s
          RelatonBib::DocumentIdentifier.new(type: type, id: id)
        end
      end

      # Fetch status.
      # @param doc [Nokogiri::HTML::Document]
      # @return [RelatonBib::DocumentStatus, NilClass]
      def fetch_status(doc)
        s = doc.at("//table/tr/td/span[contains(@id, 'Label7')]")
        return unless s

        status = s.text == "In force" ? "Published" : "Withdrawal"
        RelatonBib::DocumentStatus.new(stage: status)
      end

      # Fetch workgroup.
      # @param doc [Nokogiri::HTML::Document]
      # @return [RelatonItu::EditorialGroup, NilClass]
      def fetch_workgroup(doc)
        wg = doc.at('//table/tr/td/span[contains(@id, "Label8")]/a')
        return unless wg

        workgroup = wg.text
        EditorialGroup.new(
          bureau: workgroup.match(/(?<=-)./).to_s,
          group: itugroup(workgroup),
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
          # r_type = r.at('./td/span[contains(@id, "Label4")]/nobr').text.downcase
          ref = r.at('./td/span[contains(@id, "title_e")]/nobr/a')
          # url = DOMAIN + ref[:href].sub(/^\./, "/ITU-T/recommendations")
          fref = RelatonBib::FormattedRef.new(content: ref.text, language: "en", script: "Latn")
          bibitem = RelatonIsoBib::IsoBibliographicItem.new(formattedref: fref)
          { type: "complements", bibitem: bibitem }
        end
      end
      # rubocop:enable Metrics/MethodLength

      # Fetch type.
      # @param doc [Nokogiri::HTML::Document]
      # @return [String]
      # def fetch_type(_doc)
      #   "recommendation"
      # end

      # Fetch titles.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      def fetch_titles(doc)
        # t = hit_data[:title].match(%r{(?<=\(\d{2}\/\d{4}\): ).*}).to_s
        # t = hit_data[:title] if t.empty?
        t = doc.at("//td[@class='title']")
        return [] unless t
        titles = t.text.split " - "
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
        pdate = doc.at("//table/tr/td/span[contains(@id, 'Label5')]")
        publish_date = pdate&.text || ob_date(doc)
        unless publish_date.empty?
          dates << { type: "published", on: publish_date }
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
        abbrev = code.sub(/-\w\s.*/, "")
        case abbrev
        when "ITU"
          name = "International Telecommunication Union"
          url = "www.itu.int"
        end
        [{ entity: { name: name, url: url, abbreviation: abbrev }, role: [type: "publisher"] }]
      end

      # Fetch ICS.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      # def fetch_ics(doc)
      #   doc.xpath('//th[contains(text(), "ICS")]/following-sibling::td/a').map do |i|
      #     code = i.text.match(/[\d\.]+/).to_s.split '.'
      #     { field: code[0], group: code[1], subgroup: code[2] }
      #   end
      # end

      # Fetch links.
      # @param doc [Nokogiri::HTML::Document]
      # @param url [String]
      # @return [Array<Hash>]
      def fetch_link(doc, url)
        links = [{ type: "src", content: url }]
        obp_elms = doc.at('//a[@title="Persistent link to download the PDF file"]')
        links << { type: "obp", content: DOMAIN + obp_elms[:href].strip } if obp_elms
        links
      end

      # Fetch copyright.
      # @param code [String]
      # @param doc [Nokogiri::HTML::Document]
      # @return [Hash]
      def fetch_copyright(code, doc)
        abbreviation = code.match(/^[^-]+/).to_s
        case abbreviation
        when "ITU"
          name = "International Telecommunication Union"
          url = "www.itu.int"
        end
        fdate = doc.at("//table/tr/td/span[contains(@id, 'Label5')]")
        from = fdate&.text || ob_date(doc)
        { owner: { name: name, abbreviation: abbreviation, url: url }, from: from }
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
