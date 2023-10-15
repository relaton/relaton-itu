module RelatonItu
  class Pubid
    class Parser < Parslet::Parser
      rule(:dash) { str("-") }
      rule(:dot) { str(".") }
      rule(:dot?) { dot.maybe }
      rule(:separator) { match['\s-'] }
      rule(:space) { match("\s") }
      rule(:num) { match["0-9"] }

      rule(:prefix) { str("ITU").as(:prefix) }
      rule(:sector) { separator >> match("[A-Z]").as(:sector) }
      rule(:type) { separator >> str("REC").as(:type) }
      rule(:type?) { type.maybe }
      rule(:code) { separator >> (match["A-Z0-9"].repeat(1) >> match["[:alnum:]/.-"].repeat).as(:code) }
      rule(:year) { (match["12"] >> num.repeat(3, 3)).as(:year) }

      rule(:month1) { num.repeat(2, 2).as(:month) }
      rule(:date1) { str(" (") >> (month1 >> str("/")).maybe >> year >> str(")") }
      rule(:month2) { match["IVX"].repeat(1, 3).as(:month) }
      rule(:date2) { str(" - ") >> num.repeat(2, 2) >> dot >> month2 >> dot >> year }
      rule(:date) { date1 | date2 }
      rule(:date?) { date.maybe }

      rule(:amd) { space >> (str("Amd") | str("Amendment")) >> dot? >> space >> num.repeat(1, 2).as(:amd) }
      rule(:amd?) { amd.maybe }

      rule(:sup) { space >> str("Suppl") >> dot? >> space >> num.repeat(1, 2).as(:suppl) }
      rule(:sup?) { sup.maybe }

      rule(:annex) { space >> str("Annex") >> space >> match["[:alnum:]"].repeat(1, 2).as(:annex) }
      rule(:annex?) { annex.maybe }

      rule(:itu_pubid) { prefix >> sector >> type? >> code >> sup? >> annex? >> date? >> amd? >> any.repeat }
      root(:itu_pubid)
    end

    attr_accessor :prefix, :sector, :type, :code, :suppl, :annex, :year, :month, :amd

    #
    # Create a new ITU publication identifier.
    #
    # @param [String] prefix
    # @param [String] sector
    # @param [String, nil] type
    # @param [String] code
    # @param [String, nil] suppl number
    # @param [String, nil] year
    # @param [String, nil] month
    # @param [String, nil] amd amendment number
    #
    def initialize(prefix:, sector:, code:, **args)
      @prefix = prefix
      @sector = sector
      @type = args[:type]
      @code, year, month = date_from_code code
      @suppl = args[:suppl]
      @annex = args[:annex]
      @year = args[:year] || year
      @month = roman_to_2digit args[:month] || month
      @amd = args[:amd]
    end

    def self.parse(id)
      id_parts = Parser.new.parse(id).to_h.transform_values(&:to_s)
      new(**id_parts)
    rescue Parslet::ParseFailed => e
      Util.warn "WARNING: `#{id}` is invalid ITU publication identifier \n" \
                "#{e.parse_failure_cause.ascii_tree}"
      raise e
    end

    def to_h(with_type: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      hash = { prefix: prefix, sector: sector, code: code }
      hash[:type] = type if type && with_type
      hash[:suppl] = suppl if suppl
      hash[:annex] = annex if annex
      hash[:year] = year if year
      hash[:month] = month if month
      hash[:amd] = amd if amd
      hash
    end

    def to_ref
      to_s ref: true
    end

    def to_s(ref: false) # rubocop:disable Metrics/AbcSize
      s = "#{prefix}-#{sector}"
      s << " #{type}" if type && !ref
      s << " #{code}"
      s << " Suppl. #{suppl}" if suppl
      s << " Annex #{annex}" if annex
      s << date_to_s
      s << " Amd #{amd}" if amd
      s
    end

    def ===(other, ignore_args = [])
      hash = to_h with_type: false
      other_hash = other.to_h with_type: false
      hash.delete(:month)
      other_hash.delete(:month)
      hash.delete(:year) if ignore_args.include?(:year)
      other_hash.delete(:year) unless hash[:year]
      hash == other_hash
    end

    private

    def date_from_code(code)
      /(?<cod>.+?)-(?<date>\d{6})(?:-I|$)/ =~ code
      return [code, nil, nil] unless cod && date

      [cod, date[0..3], date[4..5]]
    end

    def roman_to_2digit(num) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return unless num

      roman_nums = { "I" => 1, "V" => 5, "X" => 10 }
      last = roman_nums[num[-1]]
      return num unless last

      return roman_nums[num].to_s.rjust(2, "0") if num.size == 1

      num.chars.each_cons(2).reduce(last) do |acc, (a, b)|
        if roman_nums[a] < roman_nums[b]
          acc - roman_nums[a]
        else
          acc + roman_nums[a]
        end
      end.to_s.rjust(2, "0")
    end

    def date_to_s
      if month && year then " (#{month}/#{year})"
      elsif year then " (#{year})"
      else ""
      end
    end
  end
end
