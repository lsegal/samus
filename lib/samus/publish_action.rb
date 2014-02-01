require_relative './action'

module Samus
  class PublishAction < Action
    def stage; 'publish' end
  end
end
