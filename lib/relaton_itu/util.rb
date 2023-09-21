module RelatonItu
  module Util
    extend RelatonBib::Util

    def self.logger
      RelatonItu.configuration.logger
    end
  end
end
