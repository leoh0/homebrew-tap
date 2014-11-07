require 'formula'

class BrewEtap < Formula
  homepage 'http://github.daumkakao.com/al-l/homebrew-etap/'
  url 'http://github.daumkakao.com/al-l/homebrew-etap.git'
  version '0.0.1'

  skip_clean 'bin'

  def install
    bin.install 'brew-etap.rb'
    bin.install 'brew-euntap.rb'
    (bin+'brew-etap.rb').chmod 0755
    (bin+'brew-euntap.rb').chmod 0755
  end
end
