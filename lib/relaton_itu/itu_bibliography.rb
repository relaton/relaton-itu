# frozen_string_literal: true

require "relaton_itu/itu_bibliographic_item"
require "relaton_itu/editorial_group"
require "relaton_itu/structured_identifier"
require "relaton_itu/itu_group"
require "relaton_itu/scrapper"
require "relaton_itu/hit_collection"
require "relaton_itu/hit"
require "relaton_itu/xml_parser"
require "relaton_itu/hash_converter"
require "date"

module RelatonItu
  # Class methods for search ISO standards.
  module ItuBibliography
    extend self

    # @param refid [RelatonItu::Pubid, String] a document reference
    # @return [RelatonItu::HitCollection]
    #
    def search(refid)
      refid = RelatonItu::Pubid.parse refid if refid.is_a? String
      if refid.to_ref =~ /(ITU[\s-]T\s\w)\.(Suppl\.|Annex)\s?(\w?\d+)/
        correct_ref = "#{$~[1]} #{$~[2]} #{$~[3]}"
        Util.info "Incorrect reference: `#{refid}`, the reference should be: `#{correct_ref}`"
      end
      HitCollection.new refid
    rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse,
           Net::HTTPHeaderSyntaxError, Net::ProtocolError, URI::InvalidURIError => e
      raise RelatonBib::RequestError, e.message
    end

    # def transform_ref(ref)
    #   ref.sub(/^ITU[\s-](\w)[\s-](?:REC[\s-])?/, 'ITU-\1')
    # end

    # @param code [String] the ISO standard Code to look up (e..g "ISO 9000")
    # @param year [String] the year the standard was published (optional)
    # @param opts [Hash] options; restricted to :all_parts if all-parts
    #   reference is required
    # @return [String] Relaton XML serialisation of reference
    def get(code, year = nil, opts = {}) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      refid = Pubid.parse code
      refid.year ||= year
      # if year.nil?
      #   /^(?<code1>[^\s]+\s[^\s]+)\s\((?:\d{2}\/)?(?<year1>\d+)\)$/ =~ code
      #   unless code1.nil?
      #     code = code1
      #     year = year1
      #   end
      # end

      ret = itubib_get1(refid)
      return nil if ret.nil?

      ret = ret.to_most_recent_reference unless refid.year || opts[:keep_year]
      ret = ret.to_all_parts if opts[:all_parts]
      ret
    end

    private

    def fetch_ref_err(refid, missed_years) # rubocop:disable Metrics/MethodLength
      # Util.warn "no match found online for `#{refid}`. " \
      #           "The code must be exactly like it is on the standards website."
      Util.info "Not found.", key: refid.to_s
      if missed_years.any?
        plural = missed_years.size > 1 ? "s" : ""
        Util.info "There was no match for `#{refid.year}` year, though there were matches " \
                  "found for `#{missed_years.join('`, `')}` year#{plural}.", key: refid.to_s
      end
      # if /\d-\d/.match? refid.code
      #   warn "[relaton-itu] The provided document part may not exist, or " \
      #        "the document may no longer be published in parts."
      # else
      # Util.warn "If you wanted to cite all document parts for the reference, " \
      #           "use `#{refid} (all parts)`.\nIf the document is not a standard, " \
      #           "use its document type abbreviation `S`, `TR`, `PAS`, `Guide`)."
      # end
      nil
    end

    def search_filter(refid) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      # %r{
      #   ^(?<pref1>ITU)?(?:-(?<type1>\w))?\s?(?<code1>[^\s/]+(?:/\w[.\d]+)?)
      #   (?:\s\(?(?<ver1>v\d+)\)?)?
      #   (?:\s\((?:(?<month1>\d{2})/)?(?<year1>\d{4})\))?
      #   (?:\s-\s(?<buldate1>\d{2}\.\w{1,4}\.\d{4}))?
      #   (?:\s(?<corr1>(?:Amd|Cor|Amendment|Corrigendum)\.?\s?\d+))?
      #   (?:\s\((?:(?<cormonth1>\d{2})/)?(?<coryear1>\d{4})\))?
      # }x =~ code
      # year ||= year1
      result = search(refid)
      # refid.code.sub!(/(?<=\.)Imp(?=\d)/, "") if result.gi_imp
      # if corr1
      #   corr1.sub!(/[.\s]+/, " ").sub!("Amendment", "Amd")
      #   corr1.sub!("Corrigendum", "Corr")
      # end
      result.select do |i|
        next true unless i.hit[:code]

        pubid = Pubid.parse i.hit[:code]
        refid.===(pubid, [:year])
        # %r{
        #   ^(?<pref2>ITU)?(?:-(?<type2>\w))?\s?(?<code2>\S+)
        #   (?:\s\(?(?<ver2>v\d+)\)?)?
        #   (?:\s\((?:(?<month2>\d{2})/)?(?<year2>\d{4})\))?
        #   (?:\s(?<corr2>(?:Amd|Cor)\.\s?\d+))?
        #   (?:\s\((?:(?<cormonth2>\d{2})/)?(?<coryear2>\d{4})\))?
        # }x =~ i.hit[:code]
        # /:[^(]+\((?<buldate2>\d{2}\.\w{1,4}\.\d{4})\)/ =~ i.hit[:title]
        # corr2&.sub!(/\.\s?/, " ")
        # pref1 == pref2 && (!type1 || type1 == type2) && code2.include?(code1) &&
        #   (!year || year == year2) && (!month1 || month1 == month2) &&
        #   corr1 == corr2 && (!coryear1 || coryear1 == coryear2) &&
        #   buldate1 == buldate2 && (!cormonth1 || cormonth1 == cormonth2) &&
        #   (!ver1 || ver1 == ver2)
      end
    end

    # Sort through the results from Isobib, fetching them three at a time,
    # and return the first result that matches the code,
    # matches the year (if provided), and which # has a title (amendments do not).
    # Only expects the first page of results to be populated.
    # Does not match corrigenda etc (e.g. ISO 3166-1:2006/Cor 1:2007)
    # If no match, returns any years which caused mismatch, for error reporting
    def isobib_results_filter(result, refid)
      missed_years = []
      result.each do |r|
        /\((?:\d{2}\/)?(?<pyear>\d{4})\)/ =~ r.hit[:code]
        if !refid.year || refid.year == pyear
          ret = r.fetch
          return { ret: ret } if ret
        end

        missed_years << pyear
      end
      { years: missed_years }
    end

    def itubib_get1(refid)
      result = search_filter(refid) || return
      ret = isobib_results_filter(result, refid)
      if ret[:ret]
        Util.info "Found: `#{ret[:ret].docidentifier.first&.id}`", key: refid.to_s
        ret[:ret]
      else
        fetch_ref_err(refid, ret[:years])
      end
    end
  end
end
