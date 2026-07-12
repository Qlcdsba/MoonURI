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
