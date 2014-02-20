module Rimpact
  class Engine < ::Rails::Engine
    isolate_namespace Rimpact
    require 'gnlookup'
    require 'ref_parsers'
  end
end
