module RelatonItu
  class HashConverter < RelatonIsoBib::HashConverter
    class << self
      # @override RelatonBib::HashConverter.hash_to_bib
      # @param args [Hash]
      # @param nested [TrueClass, FalseClass]
      # @return [Hash]
      # def hash_to_bib(args, nested = false)
      #   ret = super
      #   return if ret.nil?

      #   doctype_hash_to_bib(ret)
      #   ret
      # end

      private

      def editorialgroup_hash_to_bib(ret)
        eg = ret[:editorialgroup]
        return unless eg

        ret[:editorialgroup] = EditorialGroup.new eg
      end
    end
  end
end
