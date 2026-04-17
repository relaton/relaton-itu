module Relaton
  module Itu
    class Bibdata < Item
      model ItemData
      include Bib::BibdataShared
    end
  end
end
