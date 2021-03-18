module RelatonItu
  class ItuGroup
    class Period
      # @return [String] group period start year
      attr_reader :start

      # @return [String, NilClass] group period end year
      attr_reader :finish

      # @params start [String]
      # @params finish [String, NilClass]
      def initialize(start:, finish: nil)
        @start = start
        @finish = finish
      end

      # @param builder [Nokogiri::XML::Builder]
      def to_xml(builder)
        builder.period do
          builder.start start
          builder.end finish if finish
        end
      end

      # @return [Hash]
      def to_hash
        hash = { "start" => start }
        hash["finish"] = finish if finish
        hash
      end

      # @param prefix [String]
      # @return [String]
      def to_asciibib(prefix)
        pref = prefix.empty? ? prefix : prefix + "."
        pref += "period"
        out = "#{pref}.start:: #{start}\n"
        out += "#{pref}.finish:: #{finish}\n" if finish
        out
      end
    end

    TYPES = %w[tsag study-group work-group].freeze

    # @return [String]
    attr_reader :name

    # @return [String, NilClass]
    attr_reader :type, :acronym

    # @return [RelatonItu::ItuGroup::Period, NilClass] group period
    attr_reader :period

    # @param type [String, NilClass]
    # @param name [String]
    # @param acronym [String, NilClass]
    # @param period [Hash, RelatonItu::ItuGroup::Period, NilClass]
    def initialize(type: nil, name:, acronym: nil, period: nil)
      if type && !TYPES.include?(type)
        raise ArgumentError, "invalid type: #{type}"
      end

      @type = type
      @name = name
      @acronym = acronym
      @period = period.is_a?(Hash) ? Period.new(**period) : period
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.parent[:type] = type if type
      builder.name name
      builder.acronym acronym if acronym
      period&.to_xml builder
    end

    # @return [Hash]
    def to_hash
      hash = { "name" => name }
      hash["type"] = type if type
      hash["acronym"] = acronym if acronym
      hash["period"] = period.to_hash if period
      hash
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix)
      pref = prefix.empty? ? prefix : prefix + "."
      out = "#{pref}name:: #{name}\n"
      out += "#{pref}type:: #{type}\n" if type
      out += "#{pref}acronym:: #{acronym}\n" if acronym
      out += period.to_asciibib prefix if period
      out
    end
  end
end
