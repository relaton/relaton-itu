# frozen_string_literal: true

# require 'isobib/iso_bibliographic_item'
require 'itubib/scrapper'
require 'itubib/hit_collection'
require "date"

module ItuBib
  # Class methods for search ISO standards.
  class ItuBibliography
    class << self
      # @param text [String]
      # @return [ItuBib::HitCollection]
      def search(text, year = nil)
        begin
          HitCollection.new text, year
        rescue
          warn "Could not access http://www.itu.int"
          []
        end
      end

      # @param code [String] the ISO standard Code to look up (e..g "ISO 9000")
      # @param year [String] the year the standard was published (optional)
      # @param opts [Hash] options; restricted to :all_parts if all-parts reference is required
      # @return [String] Relaton XML serialisation of reference
      def get(code, year, opts)
        code += '-1' if opts[:all_parts]
        ret = itubib_get1(code, year, opts)
        return nil if ret.nil?
        ret.to_most_recent_reference unless year || opts[:keep_year]
        ret.to_all_parts if opts[:all_parts]
        ret
      end

      private

      def fetch_ref_err(code, year, missed_years)
        id = year ? "#{code}:#{year}" : code
        warn "WARNING: no match found online for #{id}. "\
          "The code must be exactly like it is on the standards website."
        warn "(There was no match for #{year}, though there were matches "\
          "found for #{missed_years.join(', ')}.)" unless missed_years.empty?
        if /\d-\d/ =~ code
          warn "The provided document part may not exist, or the document "\
            "may no longer be published in parts."
        else
          warn "If you wanted to cite all document parts for the reference, "\
            "use \"#{code} (all parts)\".\nIf the document is not a standard, "\
            "use its document type abbreviation (TS, TR, PAS, Guide)."
        end
        nil
      end

      def fetch_pages(s, n)
        workers = WorkersPool.new n
        workers.worker { |w| { i: w[:i], hit: w[:hit].fetch } }
        s.each_with_index { |hit, i| workers << { i: i, hit: hit } }
        workers.end
        workers.result.sort { |x, y| x[:i] <=> y[:i] }.map { |x| x[:hit] }
      end

      def search_filter(code)
        docidrx = %r{^ITU-T\s[^\s]+}
        warn "fetching #{code}..."
        result = search(code)
        result.select do |i|
          i.hit[:code] &&
            i.hit[:code].match(docidrx).to_s == code
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
        result.each_slice(3) do |s| # ISO website only allows 3 connections
          fetch_pages(s, 3).each_with_index do |r, i|
            return { ret: r } if !year
            r.dates.select { |d| d.type == "published" }.each do |d|
              return { ret: r } if year.to_i == d.on.year
              missed_years << d.on.year
            end
          end
        end
        { years: missed_years }
      end

      def itubib_get1(code, year, opts)
        result = search_filter(code) or return nil
        ret = isobib_results_filter(result, year)
        return ret[:ret] if ret[:ret]
        fetch_ref_err(code, year, ret[:years])
      end
    end
  end
end
