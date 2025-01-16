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
      rule(:date2) { str(" - ") >> num.repeat(2, 2).as(:day) >> dot >> month2 >> dot >> year }
      rule(:date) { date1 | date2 }
      rule(:date?) { date.maybe }

      rule(:amd_month) { num.repeat(2, 2) }
      rule(:amd_year) { num.repeat(4, 4) }
      rule(:amd_date) { str(" (") >> (amd_month >> str("/") >> amd_year).as(:amd_date) >> str(")") }
      rule(:amd_date?) { amd_date.maybe }
      rule(:amd) { space >> (str("Amd") | str("Amendment")) >> dot? >> space >> num.repeat(1, 2).as(:amd) >> amd_date? }
      rule(:amd?) { amd.maybe }

      rule(:sup) { space >> str("Suppl") >> dot? >> space >> num.repeat(1, 2).as(:suppl) }
      rule(:sup?) { sup.maybe }

      rule(:annex) { space >> str("Annex") >> space >> match["[:alnum:]"].repeat(1, 2).as(:annex) }
      rule(:annex?) { annex.maybe }

      rule(:ver) { space >> str("(V") >> num.repeat(1, 2).as(:version) >> str(")") }
      rule(:ver?) { ver.maybe }

      rule(:itu_pubid_sector) { prefix >> sector >> type? >> code >> sup? >> annex? >> ver? >> date? >> amd? >> any.repeat }
      rule(:itu_pubid_no_sector) { prefix >> type? >> code >> sup? >> annex? >> ver? >> date? >> amd? >> any.repeat }
      rule(:itu_pubid) { itu_pubid_sector | itu_pubid_no_sector }
      root(:itu_pubid)
    end

    attr_accessor :prefix, :sector, :type, :code, :suppl, :annex, :version, :year, :month, :day, :amd, :amd_date

    #
    # Create a new ITU publication identifier.
    #
    # @param [String] prefix
    # @param [String] sector
    # @param [String, nil] type
    # @param [String] code
    # @param [String, nil] suppl number
    # @param [String, nil] version
    # @param [String, nil] year
    # @param [String, nil] month
    # @param [String, nil] day
    # @param [String, nil] amd amendment number
    # @param [String, nil] amd_date amendment
    #
    def initialize(prefix:, code:, **args)
      @prefix = prefix
      @sector = args[:sector]
      @type = args[:type]
      @day = args[:day]
      @code, year, month = date_from_code code
      @suppl = args[:suppl]
      @annex = args[:annex]
      @version = args[:version]
      @year = args[:year] || year
      @month = roman_to_2digit args[:month] || month
      @amd = args[:amd]
      @amd_date = args[:amd_date]
    end

    def self.parse(id)
      id_parts = Parser.new.parse(id).to_h.transform_values(&:to_s)
      new(**id_parts)
    rescue Parslet::ParseFailed => e
      Util.error  "`#{id}` is invalid ITU publication identifier\n" \
                  "#{e.parse_failure_cause.ascii_tree}"
      raise e
    end

    def to_h(with_type: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      hash = { prefix: prefix, code: code }
      hash[:sector] = sector if sector
      hash[:type] = type if type && with_type
      hash[:suppl] = suppl if suppl
      hash[:annex] = annex if annex
      hash[:version] = version if version
      hash[:year] = year if year
      hash[:month] = month if month
      hash[:day] = day if day
      hash[:amd] = amd if amd
      hash[:amd_date] = amd_date if amd_date
      hash
    end

    def to_ref
      to_s ref: true
    end

    def to_s(ref: false) # rubocop:disable Metrics/AbcSize
      s = prefix.dup
      s << "-#{sector}" if sector
      s << " #{type}" if type && !ref
      s << " #{code}"
      s << " Suppl. #{suppl}" if suppl
      s << " Annex #{annex}" if annex
      s << " (V#{version})" if version
      s << date_to_s
      s << " Amd #{amd}" if amd
      s << " (#{amd_date})" if amd_date
      s
    end

    def ===(other, ignore_args = [])
      hash = to_h with_type: false
      other_hash = other.to_h with_type: false
      hash.delete(:version) if ignore_args.include?(:version)
      other_hash.delete(:version) unless hash[:version]
      hash.delete(:day)
      other_hash.delete(:day)
      hash.delete(:month)
      other_hash.delete(:month)
      hash.delete(:year) if ignore_args.include?(:year)
      other_hash.delete(:year) unless hash[:year]
      hash.delete(:amd_date) if ignore_args.include?(:amd_date)
      other_hash.delete(:amd_date) unless hash[:amd_date]
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

    def month_to_roman
      int = month.to_i
      return month unless int.between? 1, 12

      roman_tens = ["", "X"]
      roman_units = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]

      tens = int / 10
      units = int % 10

      roman_tens[tens] + roman_units[units]
    end

    def date_to_s
      # if code.match?(/^OB\./) && day && month
      #   " - #{day}.#{month_to_roman}.#{year}"
      if month && year then " (#{month}/#{year})"
      elsif year then " (#{year})"
      else ""
      end
    end
  end
end
