// Black-box regression suite for application-facing APIs.

///|
test "URIBuilder builds checked HTTP resources" {
  let uri = URIBuilder::new()
    .scheme(Some("https"))
    .host("api.example.com", port=443)
    .path("/v1")
    .append_path("users")
    .append_path("42")
    .query_param("include", "profile")
    .fragment(Some("details"))
    .build_checked()
    .unwrap()
  assert_eq(
    uri.to_string(),
    "https://api.example.com:443/v1/users/42?include=profile#details",
  )
}

///|
test "URIBuilder query and fragment normalization" {
  let uri = URIBuilder::new()
    .scheme(Some("https"))
    .host("example.com")
    .path("/")
    .query(Some("?q=hello%20world"))
    .fragment(None)
    .build()
  assert_eq(uri.to_string(), "https://example.com/?q=hello%20world")
}

///|
test "URIBuilder reports invalid authority" {
  let result = URIBuilder::new()
    .scheme(Some("https"))
    .host("", port=70000)
    .build_checked()
  assert_true(result is Err(_))
}

///|
test "path operations cover roots, files, and dot segments" {
  assert_eq(join_path(["/api/", "/v1", "users", "42"]), "/api/v1/users/42")
  assert_eq(join_path(["", "api", "", "v1/"]), "api/v1/")
  assert_eq(path_basename("/var/lib/moonuri/index.mbt"), "index.mbt")
  assert_eq(path_basename("/var/lib/moonuri/"), "moonuri")
  assert_eq(path_dirname("/var/lib/moonuri/index.mbt"), "/var/lib/moonuri")
  assert_eq(path_dirname("/index.mbt"), "/")
  assert_true(path_extension("index.mbt") is Some("mbt"))
  assert_true(path_extension(".env") is None)
  assert_eq(replace_basename("/api/users/old", "new"), "/api/users/new")
  assert_eq(canonical_path("/a/b/../c/./d"), "/a/c/d")
}

///|
test "security helpers classify hosts and validation facts" {
  let local_uri = parse("http://localhost:8080/health").unwrap()
  assert_true(local_uri.is_loopback())
  assert_true(local_uri.is_http_url())
  assert_true(local_uri.is_valid())
  assert_eq(local_uri.request_target(), "/health")
  let malformed = URI::new(Some("1http"), None, "/", None, None)
  assert_true(malformed.validation_issues().length() > 0)
  assert_true(!malformed.is_valid())
}

///|
test "RFC resolution matrix retains query and fragment rules" {
  let base = parse("http://a/b/c/d;p?q").unwrap()
  let cases = [
    ("g", "http://a/b/c/g"),
    ("./g", "http://a/b/c/g"),
    ("g/", "http://a/b/c/g/"),
    ("/g", "http://a/g"),
    ("//g", "http://g"),
    ("?y", "http://a/b/c/d;p?y"),
    ("g?y", "http://a/b/c/g?y"),
    ("#s", "http://a/b/c/d;p?q#s"),
    ("../g", "http://a/b/g"),
    ("../../g", "http://a/g"),
    ("../../", "http://a/"),
  ]
  for pair in cases {
    let (reference, expected) = pair
    assert_eq(base.resolve_string(reference).unwrap().to_string(), expected)
  }
}

///|
test "percent encoding boundary matrix" {
  let values = [
    "", "a", "a b", "a/b", "a?b", "a#b", "a+b", "a&b", "a=b", "中", "😀", "é",
    "%", "[]", "{}", "~._-", "line\nfeed",
  ]
  for value in values {
    let encoded = percent_encode(value, true)
    assert_eq(percent_decode(encoded).unwrap(), value)
  }
  assert_true(percent_decode("%E4%B8%AD") is Ok(_))
  assert_true(percent_decode("%F0%9F%98%80") is Ok(_))
  assert_true(percent_decode("%E4%B8") is Err(_))
  assert_true(percent_decode("%ED%A0%80") is Err(_))
}

///|
test "host validator boundary matrix" {
  let valid_ipv4 = ["0.0.0.0", "1.2.3.4", "192.168.1.1", "255.255.255.255"]
  for host in valid_ipv4 {
    assert_true(is_ipv4(host))
  }
  let invalid_ipv4 = [
    "", "01.2.3.4", "1.2.3", "1.2.3.4.5", "256.1.1.1", "a.1.1.1",
  ]
  for host in invalid_ipv4 {
    assert_true(!is_ipv4(host))
  }
  let valid_ipv6 = [
    "::", "::1", "2001:db8::1", "fe80::abcd", "::ffff:192.0.2.1",
  ]
  for host in valid_ipv6 {
    assert_true(is_ipv6(host))
  }
  let invalid_ipv6 = ["", ":", "1:2:3:4:5:6:7:8:9", "1::2::3", "gggg::1"]
  for host in invalid_ipv6 {
    assert_true(!is_ipv6(host))
  }
}
