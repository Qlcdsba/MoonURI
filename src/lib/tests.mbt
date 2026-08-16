// MoonURI unit tests

///|
test "percent encode and decode unreserved" {
  let s = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
  let encoded = percent_encode(s, true)
  assert_eq(encoded, s)
  let decoded = percent_decode(encoded).unwrap()
  assert_eq(decoded, s)
}

///|
test "percent encode and decode reserved and special" {
  let s = "hello world! @/:?#[]"
  let encoded = percent_encode(s, true)
  assert_eq(encoded, "hello%20world%21%20%40%2F%3A%3F%23%5B%5D")
  let decoded = percent_decode(encoded).unwrap()
  assert_eq(decoded, s)
}

///|
test "percent encode and decode UTF-8 chinese" {
  let s = "你好，世界！"
  let encoded = percent_encode(s, true)
  assert_eq(encoded, "%E4%BD%A0%E5%A5%BD%EF%BC%8C%E4%B8%96%E7%95%8C%EF%BC%81")
  let decoded = percent_decode(encoded).unwrap()
  assert_eq(decoded, s)
}

///|
test "percent decode invalid sequences" {
  assert_eq(percent_decode("%") is Err(_), true)
  assert_eq(percent_decode("%1") is Err(_), true)
  assert_eq(percent_decode("%1G") is Err(_), true)
}

///|
test "is_ipv4 validator" {
  assert_eq(is_ipv4("127.0.0.1"), true)
  assert_eq(is_ipv4("255.255.255.255"), true)
  assert_eq(is_ipv4("0.0.0.0"), true)

  assert_eq(is_ipv4("256.0.0.1"), false)
  assert_eq(is_ipv4("127.0.0.01"), false) // no leading zero
  assert_eq(is_ipv4("127.0.0"), false)
  assert_eq(is_ipv4("127.0.0.1.2"), false)
  assert_eq(is_ipv4("abc.def.ghi.jkl"), false)
}

///|
test "is_ipv6 validator" {
  assert_eq(is_ipv6("2001:db8::1"), true)
  assert_eq(is_ipv6("::1"), true)
  assert_eq(is_ipv6("::"), true)
  assert_eq(is_ipv6("2001:db8:85a3:0:0:8a2e:370:7334"), true)
  assert_eq(is_ipv6("::ffff:192.0.2.128"), true) // IPv4-mapped

  assert_eq(is_ipv6("2001:db8::1::2"), false) // double ::
  assert_eq(is_ipv6("2001:db8:85a3:0:0:8a2e:370:7334:5678"), false) // too long
  assert_eq(is_ipv6("2001:db8:85a3::192.168.1.1.1"), false) // invalid mapped
}

///|
test "is_ipv6_literal validator" {
  assert_eq(is_ipv6_literal("[2001:db8::1]"), true)
  assert_eq(is_ipv6_literal("[::1]"), true)
  assert_eq(is_ipv6_literal("2001:db8::1"), false) // no brackets
}

///|
test "parse complete absolute URI" {
  let uri_str = "http://user:pass@example.com:8080/path/to/resource?query=1&var=2#fragment"
  let uri = parse(uri_str).unwrap()

  assert_eq(uri.scheme == Some("http"), true)
  let auth = uri.authority.unwrap()
  assert_eq(auth.userinfo == Some("user:pass"), true)
  assert_eq(auth.host, "example.com")
  assert_eq(auth.port == Some(8080), true)
  assert_eq(uri.path, "/path/to/resource")
  assert_eq(uri.query == Some("query=1&var=2"), true)
  assert_eq(uri.fragment == Some("fragment"), true)

  assert_eq(uri.to_string(), uri_str)
}

///|
test "parse relative URI" {
  let uri_str = "/path/to/resource?query=1#fragment"
  let uri = parse(uri_str).unwrap()

  assert_eq(uri.scheme == None, true)
  assert_eq(uri.authority is None, true)
  assert_eq(uri.path, "/path/to/resource")
  assert_eq(uri.query == Some("query=1"), true)
  assert_eq(uri.fragment == Some("fragment"), true)

  assert_eq(uri.to_string(), uri_str)
}

///|
test "parse IPv6 host URI" {
  let uri_str = "http://[2001:db8::1]:80/path"
  let uri = parse(uri_str).unwrap()

  assert_eq(uri.scheme == Some("http"), true)
  let auth = uri.authority.unwrap()
  assert_eq(auth.host, "[2001:db8::1]")
  assert_eq(auth.port == Some(80), true)
  assert_eq(uri.path, "/path")
}

///|
test "URI relative resolution RFC 3986 Section 5.4 tests" {
  let base = parse("http://a/b/c/d;p?q").unwrap()

  // Normal examples
  assert_eq(base.resolve(parse("g:h").unwrap()).to_string(), "g:h")
  assert_eq(base.resolve(parse("g").unwrap()).to_string(), "http://a/b/c/g")
  assert_eq(base.resolve(parse("./g").unwrap()).to_string(), "http://a/b/c/g")
  assert_eq(base.resolve(parse("g/").unwrap()).to_string(), "http://a/b/c/g/")
  assert_eq(base.resolve(parse("/g").unwrap()).to_string(), "http://a/g")
  assert_eq(base.resolve(parse("//g").unwrap()).to_string(), "http://g")
  assert_eq(
    base.resolve(parse("?y").unwrap()).to_string(),
    "http://a/b/c/d;p?y",
  )
  assert_eq(base.resolve(parse("g?y").unwrap()).to_string(), "http://a/b/c/g?y")
  assert_eq(
    base.resolve(parse("#s").unwrap()).to_string(),
    "http://a/b/c/d;p?q#s",
  )
  assert_eq(base.resolve(parse("g#s").unwrap()).to_string(), "http://a/b/c/g#s")
  assert_eq(
    base.resolve(parse("g?y#s").unwrap()).to_string(),
    "http://a/b/c/g?y#s",
  )
  assert_eq(base.resolve(parse(";x").unwrap()).to_string(), "http://a/b/c/;x")
  assert_eq(base.resolve(parse("g;x").unwrap()).to_string(), "http://a/b/c/g;x")
  assert_eq(
    base.resolve(parse("g;x?y#s").unwrap()).to_string(),
    "http://a/b/c/g;x?y#s",
  )
  assert_eq(base.resolve(parse("").unwrap()).to_string(), "http://a/b/c/d;p?q")

  assert_eq(base.resolve(parse(".").unwrap()).to_string(), "http://a/b/c/")
  assert_eq(base.resolve(parse("./").unwrap()).to_string(), "http://a/b/c/")
  assert_eq(base.resolve(parse("..").unwrap()).to_string(), "http://a/b/")
  assert_eq(base.resolve(parse("../").unwrap()).to_string(), "http://a/b/")
  assert_eq(base.resolve(parse("../g").unwrap()).to_string(), "http://a/b/g")
  assert_eq(base.resolve(parse("../..").unwrap()).to_string(), "http://a/")
  assert_eq(base.resolve(parse("../../").unwrap()).to_string(), "http://a/")
  assert_eq(base.resolve(parse("../../g").unwrap()).to_string(), "http://a/g")
}

///|
test "URLSearchParams usage" {
  let sp = URLSearchParams::new("?key1=val1&key2=val2&key1=val3")
  assert_eq(sp.get("key1") == Some("val1"), true)
  assert_eq(sp.get_all("key1") == ["val1", "val3"], true)
  assert_eq(sp.has("key2"), true)
  assert_eq(sp.has("key3"), false)

  sp.append("key3", "val4")
  assert_eq(sp.get("key3") == Some("val4"), true)

  sp.set("key1", "new_val")
  assert_eq(sp.get_all("key1") == ["new_val"], true)

  sp.delete("key2")
  assert_eq(sp.has("key2"), false)

  assert_eq(sp.to_string(), "key1=new_val&key3=val4")
}

///|
test "URI normalization syntax tests" {
  let uri = parse("HTTP://User%3apass@EXAMPLE.COM:80/a/b/../c?q=1%3d2#f%3da").unwrap()
  let normalized = uri.normalize()
  assert_eq(
    normalized.to_string(),
    "http://User%3Apass@example.com:80/a/c?q=1%3D2#f%3Da",
  )
}

///|
test "URI Template Level 1 expansion" {
  let vars = {
    "var": StringValue("value"),
    "hello": StringValue("Hello World!"),
    "list": ListValue(["red", "green", "blue"]),
  }

  // Simple string expansion
  assert_eq(
    expand_template("http://example.com/{var}", vars),
    "http://example.com/value",
  )
  // Percent encoding
  assert_eq(expand_template("/path/{hello}", vars), "/path/Hello%20World%21")
  // List expansion (comma separated)
  assert_eq(expand_template("/colors/{list}", vars), "/colors/red,green,blue")
  // Missing variable
  assert_eq(expand_template("/missing/{undef}", vars), "/missing/")
  // Literal braces
  assert_eq(expand_template("/literal/{", vars), "/literal/{")
}

///|
test "parse should reject invalid percent-encoding" {
  // Invalid hex after %
  assert_eq(parse("http://example.com/path%1G") is Err(_), true)
  assert_eq(parse("http://example.com/path%") is Err(_), true)
  assert_eq(parse("http://example.com/path%1") is Err(_), true)
}

///|
test "parse should reject invalid UTF-8 in percent-encoding" {
  // 0xC0 0x80 is an invalid overlong encoding in UTF-8
  assert_eq(parse("http://example.com/path%C0%80") is Err(_), true)
  // 0xFF is an invalid UTF-8 byte
  assert_eq(parse("http://example.com/path%FF") is Err(_), true)
  assert_eq(parse("http://example.com/path%ED%A0%80") is Err(_), true)
}

///|
/// A colon in the first relative path segment cannot be mistaken for an invalid scheme.
test "parse should reject invalid URI schemes" {
  assert_eq(parse("1http://example.com") is Err(_), true)
  assert_eq(parse("-http://example.com") is Err(_), true)
  assert_eq(parse("http+unix://example.com") is Ok(_), true)
}

///|
test "normalize should decode unreserved characters" {
  // %41 is 'A', %7e is '~', %2D is '-', %2e is '.', %5F is '_'
  // These are unreserved characters and should be decoded.
  let uri = parse("http://example.com/%41%7e%2D%2e%5F%21").unwrap()
  let normalized = uri.normalize()
  assert_eq(normalized.to_string(), "http://example.com/A~-._%21")
}

///|
/// RFC 3986 Section 5.4 abnormal references must not escape the authority.
test "URI relative resolution abnormal references" {
  let base = parse("http://a/b/c/d;p?q").unwrap()
  let cases = [
    ("../../../g", "http://a/g"),
    ("../../../../g", "http://a/g"),
    ("/./g", "http://a/g"),
    ("/../g", "http://a/g"),
    ("g.", "http://a/b/c/g."),
    (".g", "http://a/b/c/.g"),
    ("g..", "http://a/b/c/g.."),
    ("..g", "http://a/b/c/..g"),
    ("./../g", "http://a/b/g"),
    ("./g/.", "http://a/b/c/g/"),
    ("g/./h", "http://a/b/c/g/h"),
    ("g/../h", "http://a/b/c/h"),
    ("g;x=1/./y", "http://a/b/c/g;x=1/y"),
    ("g;x=1/../y", "http://a/b/c/y"),
    ("g?y/./x", "http://a/b/c/g?y/./x"),
    ("g#s/./x", "http://a/b/c/g#s/./x"),
  ]
  for pair in cases {
    let (reference, expected) = pair
    assert_eq(base.resolve_string(reference).unwrap().to_string(), expected)
  }
}

///|
/// Percent normalization applies to the host as well as userinfo and paths.
test "normalize host percent-encoded unreserved characters" {
  let uri = parse("HTTP://EX%41MPLE.com/%7e?q=%41#%7e").unwrap()
  assert_eq(uri.normalize().to_string(), "http://example.com/~?q=A#~")
}

///|
/// Realistic application URLs exercise Unicode, credentials, ports, and query duplicates.
test "application URL inspection and redaction" {
  let uri = parse(
    "HTTPS://alice:secret@[2001:db8::1]:8443/api/v1/items/%E4%B8%AD?tag=moon&tag=bit#docs",
  ).unwrap()
  assert_true(uri.kind() is Absolute)
  assert_eq(uri.is_absolute(), true)
  assert_eq(uri.is_http_url(), true)
  assert_eq(uri.is_loopback(), false)
  assert_true(uri.origin() is Some(_))
  assert_eq(
    uri.redacted(),
    "HTTPS://[2001:db8::1]:8443/api/v1/items/%E4%B8%AD?tag=moon&tag=bit",
  )
  assert_eq(uri.request_target(), "/api/v1/items/%E4%B8%AD?tag=moon&tag=bit")
  assert_true(uri.path_segments() == ["api", "v1", "items", "%E4%B8%AD"])
  assert_true(
    uri.decode_path_segments().unwrap() == ["api", "v1", "items", "中"],
  )
}

///|
/// All reference forms used by routers and link resolvers remain distinguishable.
test "URI reference classification boundaries" {
  assert_true(parse("https://example.com").unwrap().kind() is Absolute)
  assert_true(parse("//example.com/path").unwrap().kind() is NetworkPath)
  assert_true(parse("/path").unwrap().kind() is AbsolutePath)
  assert_true(parse("path/to").unwrap().kind() is RelativePath)
  assert_true(parse("?only=query").unwrap().kind() is Empty)
  assert_true(parse("").unwrap().kind() is Empty)
}

///|
/// Credentials and fragments are removed independently for safe observability.
test "safe logging and cache key behavior" {
  let uri = parse("HTTP://user:pass@EXAMPLE.COM:80/a/../b?x=%41#section").unwrap()
  assert_eq(
    uri.without_userinfo().to_string(),
    "HTTP://EXAMPLE.COM:80/a/../b?x=%41#section",
  )
  assert_eq(
    uri.without_fragment().to_string(),
    "HTTP://user:pass@EXAMPLE.COM:80/a/../b?x=%41",
  )
  assert_eq(uri.cache_key(), "http://user:pass@example.com:80/b?x=A")
}

///|
/// Query mutation preserves duplicate-key semantics and stable ordering.
test "query helpers and stable sorting" {
  let uri = parse("https://example.com/search?z=9&a=1&a=2").unwrap()
  assert_true(query_values(uri.query.unwrap(), "a") == ["1", "2"])
  assert_eq(
    uri.set_query_param("page", "2").to_string(),
    "https://example.com/search?z=9&a=1&a=2&page=2",
  )
  assert_eq(
    uri.remove_query_param("a").to_string(),
    "https://example.com/search?z=9",
  )
  assert_eq(
    uri.sorted_query().to_string(),
    "https://example.com/search?a=1&a=2&z=9",
  )
  assert_eq(canonical_query("z=9&a=1&a=2"), "a=1&a=2&z=9")
  assert_true(first_non_empty("id=&id=42", "id") is Some("42"))
}

///|
/// SearchParams edge cases cover empty values, duplicate keys, and encoding.
test "URLSearchParams edge matrix" {
  let p = URLSearchParams::new("?a&b=&a=3&space=hello+world&encoded=%E4%B8%AD")
  assert_eq(p.size(), 5)
  assert_true(p.get("a") is Some(""))
  assert_true(p.get_all("a") == ["", "3"])
  assert_true(p.keys() == ["a", "b", "a", "space", "encoded"])
  assert_true(p.values() == ["", "", "3", "hello world", "中"])
  assert_eq(
    p.to_query_string(),
    "?a=&b=&a=3&space=hello%20world&encoded=%E4%B8%AD",
  )
  p.sort()
  assert_eq(p.to_string(), "a=&a=3&b=&encoded=%E4%B8%AD&space=hello%20world")
}

///|
/// Ports and authorities reject malformed or unsafe boundary spellings.
test "authority boundary validation" {
  assert_true(parse("http:///missing-host") is Err(_))
  assert_true(parse("http://example.com:") is Err(_))
  assert_true(parse("http://example.com:65536") is Err(_))
  assert_true(parse("http://example.com:65535") is Ok(_))
  assert_true(parse("http://[::1]:0/") is Ok(_))
  assert_true(classify_host("127.0.0.1") is IPv4)
  assert_true(classify_host("[::1]") is IPv6)
  assert_true(classify_host("example.com") is RegisteredName)
  assert_eq(is_loopback_host("localhost"), true)
  assert_eq(is_loopback_host("example.com"), false)
}

///|
/// RFC 3986-style corpus cases provide regression coverage beyond happy paths.
test "URI corpus regression cases" {
  let cases = [
    "mailto:John.Doe@example.com", "urn:oasis:names:specification:docbook:dtd:xml:4.1.2",
    "http://example.com/a%2Fb", "https://example.com:443/", "//cdn.example.com/assets/app.js",
    "/a/b/../c", "a/./b?x=1#frag", "?q=hello%20world", "#fragment-only", "http://[2001:db8::8a2e:370:7334]/",
  ]
  for value in cases {
    let parsed = parse(value).unwrap()
    assert_eq(parsed.is_valid(), true)
    assert_true(parse(parsed.to_string()) is Ok(_))
  }
}
