require 'heroku/bouncer/lockbox'

# Encapsulates encrypting and decrypting a hash of data. Does not store the
# key that is passed in.
class Heroku::Bouncer::DecryptedHash < Hash

  Lockbox = ::Heroku::Bouncer::Lockbox

  def initialize(decrypted_hash = nil)
    super
    replace(decrypted_hash) if decrypted_hash
  end

  def self.unlock(data, key)
    if data && data = Lockbox.new(key).unlock(data)
      data, digest = data.split("--")
      if digest == Lockbox.generate_hmac(data, key)
        data = data.unpack('m*').first
        data = Marshal.load(data)
        new(data)
      else
        new
      end
    else
      new
    end
  end

  def lock(key)
    # marshal a Hash, not a DecryptedHash
    data = {}.replace(self)
    data = Marshal.dump(data)
    data = [data].pack('m*')
    data = "#{data}--#{Lockbox.generate_hmac(data, key)}"
    Lockbox.new(key).lock(data)
  end

end
