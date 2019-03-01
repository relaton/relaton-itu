require "itubib/version"
require 'itubib/itu_bibliography'

if defined? Relaton
  require_relative 'relaton/processor'
  Relaton::Registry.instance.register(Relaton::ItuBib::Processor)
end

module ItuBib
  class Error < StandardError; end
  # Your code goes here...
end
