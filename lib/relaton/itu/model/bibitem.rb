module Relaton
  module Itu
    class Bibitem < Item
      model ItemData
      include Bib::BibitemShared
    end
  end
end
