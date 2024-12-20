defmodule NormalizeUrlTest do
  use ExUnit.Case
  doctest NormalizeUrl

  test "returns empty string if url is not binary" do
    assert(NormalizeUrl.normalize_url(nil) == "")
    assert(NormalizeUrl.normalize_url(123) == "")
  end

  test "adds a protocol by default" do
    assert(NormalizeUrl.normalize_url("example.com") == "http://example.com")
    assert(NormalizeUrl.normalize_url("example.com/dir") == "http://example.com/dir")
    assert(NormalizeUrl.normalize_url("example.com:3000") == "http://example.com:3000")
    assert(NormalizeUrl.normalize_url("example.com:3000/dir") == "http://example.com:3000/dir")
  end

  test "keeps the http protocol" do
    assert(NormalizeUrl.normalize_url("http://google.com") == "http://google.com")
  end

  test "keeps the https protocol" do
    assert(
      NormalizeUrl.normalize_url("https://google.com", add_root_path: true) ==
        "https://google.com/"
    )
  end

  test "keeps the mailto protocol" do
    assert(NormalizeUrl.normalize_url("mailto:joe@example.com") == "mailto:joe@example.com")
  end

  test "keeps the javascript protocol" do
    assert(NormalizeUrl.normalize_url("javascript:alert('hey')") == "javascript:alert('hey')")
  end

  test "handles ftp protocols" do
    assert(NormalizeUrl.normalize_url("ftp://google.com") == "ftp://google.com")
  end

  test "handles ftp protocols with fragments" do
    assert(NormalizeUrl.normalize_url("ftp://google.com#blah") == "ftp://google.com")
  end

  test "handles a url that starts with ftp" do
    assert(NormalizeUrl.normalize_url("ftp.com") == "http://ftp.com")
  end

  test "strips a relative protocol and replaces with http" do
    assert(NormalizeUrl.normalize_url("//google.com") == "http://google.com")
  end

  test "adds the correct protocol if 8080 is specified" do
    assert(NormalizeUrl.normalize_url("//google.com:8080") == "https://google.com")
  end

  test "adds the correct protocol if 80 is specified" do
    assert(NormalizeUrl.normalize_url("//google.com:80") == "http://google.com")
  end

  test "sorts query params" do
    assert(
      NormalizeUrl.normalize_url("google.com?b=foo&a=bar&123=hi") ==
        "http://google.com?123=hi&a=bar&b=foo"
    )
  end

  test "encodes back query params" do
    assert(
      NormalizeUrl.normalize_url("google.com?b=foo's+bar&a=joe+smith") ==
        "http://google.com?a=joe+smith&b=foo%27s+bar"
    )
  end

  test "strips url fragment" do
    assert(NormalizeUrl.normalize_url("johnotander.com#about") == "http://johnotander.com")
  end

  test "strips www" do
    assert(NormalizeUrl.normalize_url("www.johnotander.com") == "http://johnotander.com")
  end

  test "does not strip a relative protocol with option normalize_protocol: false" do
    assert(
      NormalizeUrl.normalize_url("//google.com", normalize_protocol: false) == "//google.com"
    )
  end

  test "does not strip www with option strip_www: false" do
    assert(
      NormalizeUrl.normalize_url("www.google.com", strip_www: false) == "http://www.google.com"
    )
  end

  test "does not strip a url fragment with option strip_fragment: false" do
    assert(
      NormalizeUrl.normalize_url("www.google.com#about.html", strip_fragment: false) ==
        "http://google.com#about.html"
    )
  end

  test "does not strip query params with option strip_params: false" do
    assert(
      NormalizeUrl.normalize_url("google.com?a=1&b=2", strip_params: false) ==
        "http://google.com?a=1&b=2"
    )
  end

  test "does strip query params with option strip_params: true" do
    assert(
      NormalizeUrl.normalize_url("google.com?a=1&b=2", strip_params: true) == "http://google.com"
    )
  end

  test "adds root path if enabled and needed" do
    assert(
      NormalizeUrl.normalize_url("http://google.com", add_root_path: true) == "http://google.com/"
    )
  end

  test "does not removes trailing slash from path if trim_trailing_slash false" do
    assert(
      NormalizeUrl.normalize_url("http://google.com/test/", trim_trailing_slash: false) ==
        "http://google.com/test/"
    )
  end

  test "removes trailing slash from path if trim_trailing_slash true" do
    assert(
      NormalizeUrl.normalize_url("http://google.com/test/", trim_trailing_slash: true) ==
        "http://google.com/test"
    )

    assert(
      NormalizeUrl.normalize_url("http://google.com",
        add_root_path: true,
        trim_trailing_slash: true
      ) == "http://google.com/"
    )
  end

  test "handles URLs with port" do
    assert NormalizeUrl.normalize_url("http://example.com:3000") == "http://example.com:3000"
    assert NormalizeUrl.normalize_url("https://example.com:3000") == "https://example.com:3000"

    assert NormalizeUrl.normalize_url("https://example.com:3000/dir") ==
             "https://example.com:3000/dir"

    assert NormalizeUrl.normalize_url("example.com:3000") == "http://example.com:3000"
    assert NormalizeUrl.normalize_url("example.com:3000/dir") == "http://example.com:3000/dir"
  end

  # Temporary patch, proper downcasing should only affect the host, not change the path, the protocol should always be downcase
  describe "downcasing" do
    test "does not downcase by default" do
      assert(
        NormalizeUrl.normalize_url("http://example.com/Path/With/Upcase") ==
          "http://example.com/Path/With/Upcase"
      )
    end

    test "downcase if explicitly activated" do
      assert(
        NormalizeUrl.normalize_url("http://example.com/Path/With/Upcase", downcase: true) ==
          "http://example.com/path/with/upcase"
      )
    end
  end
end
