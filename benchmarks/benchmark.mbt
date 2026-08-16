// Repeatable corpus runner. It reports work counts rather than machine-specific
// timings so CI can use it as a smoke test on every supported backend.

///|
fn main {
  let corpus = [
    "https://www.example.com/", "https://api.github.com/repos/moonbitlang/moonbit",
    "https://user:password@example.com:8443/api/v1/items?q=moonbit#top", "http://127.0.0.1:8080/healthz",
    "http://[::1]:3000/metrics", "//cdn.example.org/assets/app.js?v=2026.08", "/docs/reference/rfc3986",
    "/search?q=uri+template&lang=zh-CN", "../images/logo.svg", "mailto:maintainer@example.org",
    "urn:example:animal:ferret:nose", "https://example.com/a/./b/../c/%E4%B8%AD",
    "https://example.com/?a=1&a=2&empty&space=hello%20world", "https://example.com:443/",
    "http://192.0.2.1/resource?id=42", "http://[2001:db8::1]/resource", "https://service.example.com/v2/items;preview?sort=name&limit=50",
    "https://example.com/path%2Fwith%2Fencoded-slashes", "https://example.com/%F0%9F%98%80",
    "https://example.com/download/file.tar.gz#checksum", "https://example.com/callback?next=%2Fdashboard",
    "https://example.com/empty?", "#section-2", "?page=2",
  ]
  let mut parsed_count = 0
  let mut normalized_bytes = 0
  let mut query_pairs = 0
  for input in corpus {
    match @lib.parse(input) {
      Ok(uri) => {
        parsed_count += 1
        normalized_bytes += uri.cache_key().length()
        query_pairs += @lib.URLSearchParams::new(uri.query.unwrap_or("")).size()
      }
      Err(error) => println("invalid corpus item: " + error)
    }
  }
  println("corpus_items=" + corpus.length().to_string())
  println("parsed_items=" + parsed_count.to_string())
  println("normalized_code_units=" + normalized_bytes.to_string())
  println("query_pairs=" + query_pairs.to_string())
}
