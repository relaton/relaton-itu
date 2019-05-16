# frozen_string_literal: true

require 'iso_bib_item'
require 'relaton_itu/hit'
require 'nokogiri'
require 'net/http'
require 'relaton_itu/workers_pool'

# Capybara.request_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new app, js_errors: false
# end
# Capybara.default_driver = :poltergeist

module RelatonItu
  # Scrapper.
  # rubocop:disable Metrics/ModuleLength
  module Scrapper
    DOMAIN = 'https://www.itu.int'

    TYPES = {
      'ISO'   => 'international-standard',
      'TS'    => 'technicalSpecification',
      'TR'    => 'technicalReport',
      'PAS'   => 'publiclyAvailableSpecification',
      'AWI'   => 'appruvedWorkItem',
      'CD'    => 'committeeDraft',
      'FDIS'  => 'finalDraftInternationalStandard',
      'NP'    => 'newProposal',
      'DIS'   => 'draftInternationalStandard',
      'WD'    => 'workingDraft',
      'R'     => 'recommendation',
      'Guide' => 'guide'
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
        doc = get_page hit_data[:url]

        # Fetch edition.
        edition = doc.at("//table/tr/td/span[contains(@id, 'Label8')]/b").text

        IsoBibItem::IsoBibliographicItem.new(
          docid:        fetch_docid(hit_data[:code]),
          edition:      edition,
          language:     ['en'],
          script:       ['Latn'],
          titles:       fetch_titles(hit_data),
          type:         fetch_type(doc),
          docstatus:    fetch_status(doc),
          ics:          [], # fetch_ics(doc),
          dates:        fetch_dates(doc),
          contributors: fetch_contributors(hit_data[:code]),
          workgroup:    fetch_workgroup(doc),
          abstract:     fetch_abstract(doc),
          copyright:    fetch_copyright(hit_data[:code], doc),
          link:         fetch_link(doc, hit_data[:url]),
          relations:    fetch_relations(doc)
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
        abstract_content = d.css('p.MsoNormal').text.gsub(/\r\n/, '')
          .gsub(/\s{2,}/, ' ').gsub(/\u00a0/, '')

        [{
          content:  abstract_content,
          language: 'en',
          script:   'Latn'
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
        resp = Net::HTTP.get_response(uri)#.encode("UTF-8")
        while resp.code == '301' || resp.code == '302' || resp.code == '303'
          uri = URI resp['location']
          resp = Net::HTTP.get_response(uri)#.encode("UTF-8")
        end
        Nokogiri::HTML(resp.body)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # Fetch docid.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Hash]
      def fetch_docid(code)
        m = code.match(/(?<=\s)(?<project>[^\s]+)-?(?<part>(?<=-)\d+|)-?(?<subpart>(?<=-)\d+|)/)
        {
          project_number: m[:project],
          part_number: m[:part],
          subpart_number: m[:subpart],
          prefix: nil,
          type: 'ITU',
          id: code
        }
      end

      # Fetch status.
      # @param doc [Nokogiri::HTML::Document]
      # @param status [String]
      # @return [Hash]
      def fetch_status(doc)
        s = doc.at("//table/tr/td/span[contains(@id, 'Label7')]").text
        if s == 'In force'
          status   = 'Published'
          stage    = '60'
          substage = '60'
        else
          status   = 'Withdrawal'
          stage    = '95'
          substage = '99'
        end
        { status: status, stage: stage, substage: substage }
      end

      # Fetch workgroup.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Hash]
      def fetch_workgroup(doc)
        wg = doc.at('//table/tr/td/span[contains(@id, "Label8")]/a').text
        { name:                'International Telecommunication Union',
          abbreviation:        'ITU',
          url:                 'www.itu.int',
          technical_committee: {
            name:   wg,
            type:   'technicalCommittee',
            number: wg.match(/\d+/)&.to_s&.to_i
          } }
      end

      # Fetch relations.
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      # rubocop:disable Metrics/MethodLength
      def fetch_relations(doc)
        doc.xpath('//div[contains(@id, "tab_sup")]//table/tr[position()>2]').map do |r|
          r_type = r.at('./td/span[contains(@id, "Label4")]/nobr').text.downcase
          type = case r_type
                 when 'in force' then 'published'
                 else r_type
                 end
          ref = r.at('./td/span[contains(@id, "title_e")]/nobr/a')
          url = DOMAIN + ref[:href].sub(/^\./, '/ITU-T/recommendations')
          { type: type, identifier: ref.text, url: url }
        end
      end

      # Fetch type.
      # @param doc [Nokogiri::HTML::Document]
      # @return [String]
      def fetch_type(doc)
        'international-standard'
      end

      # Fetch titles.
      # @param hit_data [Hash]
      # @return [Array<Hash>]
      def fetch_titles(hit_data)
        titles = hit_data[:title].split ' - '
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
          title_main:  main,
          title_part:  part,
          language:    'en',
          script:      'Latn'
        }]
      end

      # Fetch dates
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      def fetch_dates(doc)
        dates = []
        publish_date = doc.at("//table/tr/td/span[contains(@id, 'Label5')]").text
        unless publish_date.empty?
          dates << { type: 'published', on: publish_date }
        end
        dates
      end

      # Fetch contributors
      # @param doc [Nokogiri::HTML::Document]
      # @return [Array<Hash>]
      def fetch_contributors(code)
        abbrev = code.sub(/-\w\s.*/, '')
        case abbrev
        when 'ITU'
          name = 'International Telecommunication Union'
          url = 'www.itu.int'
        end
        [{ entity: { name: name, url: url, abbreviation: abbrev }, roles: ['publisher'] }]
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
        links = [{ type: 'src', content: url }]
        obp_elms = doc.at('//table/tr/td/span[contains(@id, "Label4")]/a')
        links << { type: 'obp', content: DOMAIN + obp_elms[:href] } if obp_elms
        links
      end

      # Fetch copyright.
      # @param code [String]
      # @param doc [Nokogiri::HTML::Document]
      # @return [Hash]
      def fetch_copyright(code, doc)
        abbreviation = code.match(/^[^-]+/).to_s
        case abbreviation
        when 'ITU'
          name = 'International Telecommunication Union'
          url = 'www.itu.int'
        end
        from = doc.at("//table/tr/td/span[contains(@id, 'Label5')]").text
        { owner: { name: name, abbreviation: abbreviation, url: url }, from: from }
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
