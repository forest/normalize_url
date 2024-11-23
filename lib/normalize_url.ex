defmodule NormalizeUrl do
  @moduledoc """
  The base module of NormalizeUrl.
  Provides URL normalization functionality using URI parsing.
  """

  @type url_options :: [
          strip_www: boolean(),
          strip_fragment: boolean(),
          strip_params: boolean(),
          normalize_protocol: boolean(),
          add_root_path: boolean(),
          trip_trailing_slash: boolean()
        ]

  @doc """
  Normalizes a URL using URI parsing and manipulation.
  """
  @spec normalize_url(String.t(), url_options()) :: String.t()
  def normalize_url(url, options \\ [])

  def normalize_url(url, options) when is_binary(url) do
    options = normalize_options(options)

    url = add_default_scheme(url, options)

    with {:ok, uri} <- URI.new(url),
         true <- supported_scheme?(uri.scheme) do
      uri
      |> normalize_scheme(options)
      |> normalize_host(options)
      |> normalize_port()
      |> normalize_path(options)
      |> normalize_query(options)
      |> normalize_fragment(options)
      |> URI.to_string()
      |> normalize_case(options)
    else
      _ -> url
    end
  end

  def normalize_url(_url, _options), do: ""

  defp add_default_scheme(url, options) do
    uri = URI.parse(url)
    schema = get_scheme(url)

    if schema do
      url
    else
      cond do
        options[:normalize_protocol] && String.starts_with?(url, "//") ->
          url = scheme_from_port(uri) <> ":" <> url
          drop_port_from_url(url)

        options[:normalize_protocol] ->
          scheme_from_port(uri) <> "://" <> url

        true ->
          url
      end
    end
  end

  defp drop_port_from_url(url) do
    url |> URI.parse() |> then(fn uri -> %{uri | port: nil} end) |> URI.to_string()
  end

  defp scheme_from_port(%{port: port}) when port in [nil, 80], do: "http"
  defp scheme_from_port(%{port: port}) when port in [8080, 443], do: "https"
  defp scheme_from_port(_), do: ""

  # Extracts the scheme from a URL, returning nil if it's not an accepted scheme.
  # Needed because URI.parse("example.com:4000") will return "example.com" as the scheme.
  defp get_scheme(url) do
    %{scheme: scheme} = URI.parse(url)

    if Enum.any?(accepted_schemes(), &(&1 == scheme)), do: scheme, else: nil
  end

  defp accepted_schemes do
    iana_schemes() ++ ["javascript"]
  end

  defp normalize_options(options) do
    Keyword.merge(
      [
        normalize_protocol: true,
        strip_www: true,
        strip_fragment: true,
        strip_params: false,
        add_root_path: false,
        trip_trailing_slash: false
      ],
      options
    )
  end

  defp supported_scheme?(scheme) when scheme in [nil, "http", "https", "ftp"], do: true
  defp supported_scheme?(_), do: false

  defp normalize_scheme(%URI{} = uri, options) do
    scheme =
      cond do
        options[:normalize_protocol] && uri.scheme == nil -> "http"
        true -> uri.scheme
      end

    %{uri | scheme: scheme}
  end

  defp normalize_host(%URI{} = uri, options) do
    host =
      if options[:strip_www] do
        String.replace(uri.host || "", ~r/^www\./, "")
      else
        uri.host
      end

    %{uri | host: host}
  end

  defp normalize_port(%URI{} = uri) do
    port =
      case {uri.scheme, uri.port} do
        {"http", 80} -> nil
        {"https", 443} -> nil
        {"ftp", 21} -> nil
        {_, port} -> port
      end

    %{uri | port: port}
  end

  defp normalize_path(%URI{} = uri, options) do
    path =
      cond do
        options[:add_root_path] && (is_nil(uri.path) || uri.path == "") ->
          "/"

        options[:trip_trailing_slash] && (!is_nil(uri.path) && uri.path != "") ->
          String.trim_trailing(uri.path, "/")

        true ->
          uri.path
      end

    %{uri | path: path}
  end

  defp normalize_query(%URI{} = uri, options) do
    query =
      if options[:strip_params] do
        nil
      else
        uri.query
        |> decode_and_encode_query()
      end

    %{uri | query: query}
  end

  defp decode_and_encode_query(nil), do: nil

  defp decode_and_encode_query(query) do
    query
    |> URI.decode_query()
    |> URI.encode_query()
  end

  defp normalize_fragment(%URI{} = uri, options) do
    fragment = if options[:strip_fragment], do: nil, else: uri.fragment
    %{uri | fragment: fragment}
  end

  defp normalize_case(url, options) do
    if options[:downcase] do
      String.downcase(url)
    else
      url
    end
  end

  # Taken from https://www.iana.org/assignments/uri-schemes/uri-schemes.txt
  defp iana_schemes do
    """
    aaa
    aaas
    about
    acap
    acct
    acr
    adiumxtra
    afp
    afs
    aim
    appdata
    apt
    attachment
    aw
    barion
    beshare
    bitcoin
    blob
    bolo
    browserext
    callto
    cap
    chrome
    chrome-extension
    cid
    coap
    coap+tcp
    coaps
    coaps+tcp
    com-eventbrite-attendee
    content
    crid
    cvs
    data
    dav
    dict
    dis
    dlna-playcontainer
    dlna-playsingle
    dns
    dntp
    dtn
    dvb
    ed2k
    example
    facetime
    fax
    feed
    feedready
    file
    filesystem
    finger
    fish
    ftp
    geo
    gg
    git
    gizmoproject
    go
    gopher
    graph
    gtalk
    h323
    ham
    hcp
    http
    https
    hxxp
    hxxps
    hydrazone
    iax
    icap
    icon
    im
    imap
    info
    iotdisco
    ipn
    ipp
    ipps
    irc
    irc6
    ircs
    iris
    iris.beep
    iris.lwz
    iris.xpc
    iris.xpcs
    isostore
    itms
    jabber
    jar
    jms
    keyparc
    lastfm
    ldap
    ldaps
    lvlt
    magnet
    mailserver
    mailto
    maps
    market
    message
    mid
    mms
    modem
    mongodb
    moz
    ms-access
    ms-browser-extension
    ms-drive-to
    ms-enrollment
    ms-excel
    ms-gamebarservices
    ms-getoffice
    ms-help
    ms-infopath
    ms-inputapp
    ms-media-stream-id
    ms-officeapp
    ms-people
    ms-project
    ms-powerpoint
    ms-publisher
    ms-search-repair
    ms-secondary-screen-contr
    ms-secondary-screen-setup
    ms-settings
    ms-settings-airplanemode
    ms-settings-bluetooth
    ms-settings-camera
    ms-settings-cellular
    ms-settings-cloudstorage
    ms-settings-connectablede
    ms-settings-displays-topo
    ms-settings-emailandaccou
    ms-settings-language
    ms-settings-location
    ms-settings-lock
    ms-settings-nfctransactio
    ms-settings-notifications
    ms-settings-power
    ms-settings-privacy
    ms-settings-proximity
    ms-settings-screenrotatio
    ms-settings-wifi
    ms-settings-workplace
    ms-spd
    ms-sttoverlay
    ms-transit-to
    ms-virtualtouchpad
    ms-visio
    ms-walk-to
    ms-whiteboard
    ms-whiteboard-cmd
    ms-word
    msnim
    msrp
    msrps
    mtqp
    mumble
    mupdate
    mvn
    news
    nfs
    ni
    nih
    nntp
    notes
    ocf
    oid
    onenote
    onenote-cmd
    opaquelocktoken
    pack
    palm
    paparazzi
    pkcs11
    platform
    pop
    pres
    prospero
    proxy
    pwid
    psyc
    qb
    query
    redis
    rediss
    reload
    res
    resource
    rmi
    rsync
    rtmfp
    rtmp
    rtsp
    rtsps
    rtspu
    secondlife
    service
    session
    sftp
    sgn
    shttp
    sieve
    sip
    sips
    skype
    smb
    sms
    smtp
    snews
    snmp
    soap.beep
    soap.beeps
    soldat
    spotify
    ssh
    steam
    stun
    stuns
    submit
    svn
    tag
    teamspeak
    tel
    teliaeid
    telnet
    tftp
    things
    thismessage
    tip
    tn3270
    tool
    turn
    turns
    tv
    udp
    unreal
    urn
    ut2004
    v-event
    vemmi
    ventrilo
    videotex
    vnc
    view-source
    wais
    webcal
    wpid
    ws
    wss
    wtai
    wyciwyg
    xcon
    xcon-userid
    xfire
    xmlrpc.beep
    xmlrpc.beeps
    xmpp
    xri
    ymsgr
    z39.50
    z39.50r
    z39.50s
    """
    |> String.split(~r/\n/, trim: true)
  end
end
