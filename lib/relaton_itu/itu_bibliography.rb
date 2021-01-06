# frozen_string_literal: true

require "relaton_bib"
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
  class ItuBibliography
    class << self
      # @param text [String]
      # @return [RelatonItu::HitCollection]
      def search(text, year = nil)
        HitCollection.new text, year
      rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
             EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
             Net::ProtocolError, OpenSSL::SSL::SSLError
        raise RelatonBib::RequestError, "Could not access http://www.itu.int"
      end

      # @param code [String] the ISO standard Code to look up (e..g "ISO 9000")
      # @param year [String] the year the standard was published (optional)
      # @param opts [Hash] options; restricted to :all_parts if all-parts reference is required
      # @return [String] Relaton XML serialisation of reference
      def get(code, year = nil, opts = {}) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        if year.nil?
          /^(?<code1>[^\s]+\s[^\s]+)\s\(\d{2}\/(?<year1>\d+)\)$/ =~ code
          unless code1.nil?
            code = code1
            year = year1
          end
        end

        code += "-1" if opts[:all_parts]
        ret = itubib_get1(code, year, opts)
        return nil if ret.nil?

        ret = ret.to_most_recent_reference unless year || opts[:keep_year]
        ret = ret.to_all_parts if opts[:all_parts]
        ret
      end

      private

      def fetch_ref_err(code, year, missed_years) # rubocop:disable Metrics/MethodLength
        id = year ? "#{code}:#{year}" : code
        warn "[relaton-itu] WARNING: no match found online for #{id}. "\
          "The code must be exactly like it is on the standards website."
        warn "[relaton-itu] (There was no match for #{year}, though there were matches "\
          "found for #{missed_years.join(', ')}.)" unless missed_years.empty?
        if /\d-\d/ =~ code
          warn "[relaton-itu] The provided document part may not exist, or the document "\
            "may no longer be published in parts."
        else
          warn "[relaton-itu] If you wanted to cite all document parts for the reference, "\
            "use \"#{code} (all parts)\".\nIf the document is not a standard, "\
            "use its document type abbreviation (TS, TR, PAS, Guide)."
        end
        nil
      end

      def search_filter(code, year) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        %r{
          ^(?<pref1>ITU)?(-(?<type1>\w))?\s?(?<code1>[^\s\/]+)
          (\s\(((?<month1>\d{2})\/)?(?<year1>\d{4})\))?
          (\s-\s(?<buldate1>\d{2}\.\w{1,4}\.\d{4}))?
          (\/(?<corr1>(Amd|Cor)\s?\d+))?
          (\s\(((?<cormonth1>\d{2})\/)?(?<coryear1>\d{4})\))?
        }x =~ code
        year ||= year1
        # docidrx = %r{\w+\.\d+|\w\sSuppl\.\s\d+} # %r{^ITU-T\s[^\s]+}
        # c = code.sub(/Imp\s?/, "").match(docidrx).to_s
        warn "[relaton-itu] (\"#{code}\") fetching..."
        result = search(code)
        code1.sub! /(?<=\.)Imp(?=\d)/, "" if result.gi_imp
        result.select do |i|
          next true unless i.hit[:code]

          %r{
            ^(?<pref2>ITU)?(-(?<type2>\w))?\s?(?<code2>[\S]+)
            (\s\(((?<month2>\d{2})\/)?(?<year2>\d{4})\))?
            (\s(?<corr2>(Amd|Cor)\.\s?\d+))?
            (\s\(((?<cormonth2>\d{2})\/)?(?<coryear2>\d{4})\))?
          }x =~ i.hit[:code]
          /:[^\(]+\((?<buldate2>\d{2}\.\w{1,4}\.\d{4})\)/ =~ i.hit[:title]
          corr2&.sub! /\.\s?/, " "
          pref1 == pref2 && (!type1 || type1 == type2) && code1 == code2 &&
            (!year || year == year2) && (!month1 || month1 == month2) &&
            corr1 == corr2 && (!coryear1 || coryear1 == coryear2) &&
            buldate1 == buldate2 && (!cormonth1 || cormonth1 == cormonth2)
        end
      end

      # Sort through the results from Isobib, fetching them three at a time,
      # and return the first result that matches the code,
      # matches the year (if provided), and which # has a title (amendments do not).
      # Only expects the first page of results to be populated.
      # Does not match corrigenda etc (e.g. ISO 3166-1:2006/Cor 1:2007)
      # If no match, returns any years which caused mismatch, for error reporting
      def isobib_results_filter(result, year)
        missed_years = []
        result.each do |r|
          return { ret: r.fetch } if !year

          /\(\d{2}\/(?<pyear>\d{4})\)/ =~ r.hit[:code]
          return { ret: r.fetch } if year == pyear

          missed_years << pyear
        end
        { years: missed_years }
      end

      def itubib_get1(code, year, _opts)
        result = search_filter(code, year) || return
        ret = isobib_results_filter(result, year)
        if ret[:ret]
          warn "[relaton-itu] (\"#{code}\") found #{ret[:ret].docidentifier.first&.id}"
          ret[:ret]
        else
          fetch_ref_err(code, year, ret[:years])
        end
      end
    end
  end
end
