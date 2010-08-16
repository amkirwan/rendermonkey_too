require 'openssl'
require 'digest/sha2'


class SecureKey
  
  def self.load
    obj = self.new
    return obj
  end
end