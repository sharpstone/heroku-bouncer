require 'openssl'

class Heroku::Bouncer::Lockbox < BasicObject

  def initialize(key)
    @key = key
  end

  def lock(str)
    aes = ::OpenSSL::Cipher::Cipher.new('aes-128-cbc').encrypt
    aes.key = @key
    iv = ::OpenSSL::Random.random_bytes(aes.iv_len)
    aes.iv = iv
    [iv + (aes.update(str) << aes.final)].pack('m0')
  end

  # decrypts string. returns nil if an error occurs
  #
  # returns nil if openssl raises an error during decryption (data
  # manipulation, key change, implementation change), or if the text to
  # decrypt is too short to possibly be good aes data.
  def unlock(str)
    str = str.unpack('m0').first
    aes = ::OpenSSL::Cipher::Cipher.new('aes-128-cbc').decrypt
    aes.key = @key
    iv = str[0, aes.iv_len]
    aes.iv = iv
    crypted_text = str[aes.iv_len..-1]
    return nil if crypted_text.nil? || iv.nil?
    aes.update(crypted_text) << aes.final
  rescue
    nil
  end

private

  def self.generate_hmac(data, key)
    ::OpenSSL::HMAC.hexdigest(::OpenSSL::Digest::SHA1.new, key, data)
  end
end
