module Syrup
  # This error is raised when the information supplied was invalid or incorrect.
  # Here are some example situations:
  #
  # * A username/password wasn't supplied.
  # * The password supplied didn't work.
  class InformationMissingError < StandardError
  end
end