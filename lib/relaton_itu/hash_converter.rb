module RelatonItu
  class HashConverter < RelatonIsoBib::HashConverter
    class << self
      private

      def editorialgroup_hash_to_bib(ret)
        eg = ret[:editorialgroup]
        return unless eg

        ret[:editorialgroup] = EditorialGroup.new eg
      end
    end
  end
end
