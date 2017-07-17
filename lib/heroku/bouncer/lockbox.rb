require 'openssl'

class Heroku::Bouncer::Lockbox < BasicObject

  def initialize(key)
    @key = key
  end

  def lock(str)
    aes = cipher.encrypt
    aes.key = @key.size > 32 ? @key[0..31] : @key
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
    aes = cipher.decrypt
    aes.key = @key.size > 32 ? @key[0..31] : @key
    iv = str[0, aes.iv_len]
    aes.iv = iv
    crypted_text = str[aes.iv_len..-1]
    return nil if crypted_text.nil? || iv.nil?
    aes.update(crypted_text) << aes.final
  rescue
    nil
  end

private

  def cipher
    if ruby_two_point_four_or_above?
      ::OpenSSL::Cipher.new('aes-256-cbc')
    else
      ::OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    end
  end

  def ruby_two_point_four_or_above?
    ::RUBY_VERSION.to_f >= 2.4
  end

  def self.generate_hmac(data, key)
    ::OpenSSL::HMAC.hexdigest(::OpenSSL::Digest::SHA1.new, key, data)
  end
end
