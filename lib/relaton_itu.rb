require "relaton_itu/version"
require "relaton_itu/itu_bibliography"

# if defined? Relaton
#   require_relative "relaton/processor"
#   Relaton::Registry.instance.register(Relaton::RelatonItu::Processor)
# end

module RelatonItu
  class Error < StandardError; end
  # Your code goes here...
end
