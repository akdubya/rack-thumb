require "mapel"

module Mapel
  class Engine
    
    # Tries performing a given command on Mapel engine.
    def try(cmd)
      begin
        self.send(cmd)
      rescue NoMethodError
      end
      self
    end
  end
end
