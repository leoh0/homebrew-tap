class TigerVnc < Formula
  homepage "http://tigervnc.org/"
  url "https://github.com/TigerVNC/tigervnc/archive/v1.6.0.tar.gz"
  sha256 "98ffe98fcfe883e6c35aec579295b53d73d2ccf62e0f6e53a73ecad993b096ca"

  bottle do
    sha256 "8ec9241b2172d2b9b496440fe14ef44763a418dcf29e4c1378bdcfa476bfdb5a" => :mavericks
  end

  depends_on "cmake" => :build
  depends_on "gnutls" => :recommended
  depends_on "jpeg-turbo"
  depends_on "gettext"
  depends_on :x11

  def install
    turbo = Formula["jpeg-turbo"]
    args = std_cmake_args + %W[
      -DJPEG_INCLUDE_DIR=#{turbo.include}
      -DJPEG_LIBRARY=#{turbo.lib}/libjpeg.dylib
      .
    ]
    system "cmake", *args
    system "make", "install"
  end
end