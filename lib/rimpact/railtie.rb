module Rimpact
  class Railtie < Rails::Railtie
    rake_tasks do
      Dir.glob(File.dirname(File.expand_path(__FILE__))+'/../recipes/**/*.rake').each {|f| load f}
    end
  end
end