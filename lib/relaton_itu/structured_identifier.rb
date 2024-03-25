module RelatonItu
  class StructuredIdentifier
    # @return [String]
    attr_reader :bureau, :docnumber

    # @return [String, NilClass]
    attr_reader :annexid

    # @param bureau [String] T, D, or R
    # @param docnumber [String]
    # @param annexid [String, NilClass]
    def initialize(bureau:, docnumber:, annexid: nil)
      unless EditorialGroup::BUREAUS.include? bureau
        Util.warn "Invalid bureau: `#{bureau}`"
      end
      @bureau = bureau
      @docnumber = docnumber
      @annexid = annexid
    end

    # @param builder [Nokogiri::XML::Builder]
    def to_xml(builder)
      builder.structuredidentifier do |b|
        b.bureau bureau
        b.docnumber docnumber
        b.annexid annexid if annexid
      end
    end

    # @return [Hash]
    def to_hash
      hash = { bureau: bureau, docnumber: docnumber }
      hash[:annexid] = annexid if annexid
      hash
    end

    # @param prefix [String]
    # @return [String]
    def to_asciibib(prefix)
      pref = prefix.empty? ? prefix : prefix + "."
      pref += "structuredidentifier"
      out = "#{pref}.bureau:: #{bureau}\n#{pref}.docnumber:: #{docnumber}\n"
      out += "#{pref}.annexid:: #{annexid}\n" if annexid
      out
    end

    def presence?
      true
    end
  end
end
