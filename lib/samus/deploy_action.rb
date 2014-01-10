require_relative './action'

module Samus
  class DeployAction < Action
    def stage; 'deploy' end
  end
end
