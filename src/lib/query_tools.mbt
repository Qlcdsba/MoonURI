// Query-string helpers for common web and service integration patterns.

///|
/// Decodes all values for a key, returning an empty array when absent.
pub fn query_values(query : String, key : String) -> Array[String] {
  URLSearchParams::new(query).get_all(key)
}

///|
/// Replaces or appends a query parameter in a URI.
pub fn URI::set_query_param(self : URI, key : String, value : String) -> URI {
  let params = URLSearchParams::new(self.query.unwrap_or(""))
  params.set(key, value)
  self.with_query(Some(params.to_string()))
}

///|
/// Removes every occurrence of a query parameter from a URI.
pub fn URI::remove_query_param(self : URI, key : String) -> URI {
  let params = URLSearchParams::new(self.query.unwrap_or(""))
  params.delete(key)
  let query = if params.size() == 0 { None } else { Some(params.to_string()) }
  self.with_query(query)
}

///|
/// Sorts query parameters and returns a normalized URI cache key.
pub fn URI::sorted_query(self : URI) -> URI {
  let params = URLSearchParams::new(self.query.unwrap_or(""))
  params.sort()
  let query = if params.size() == 0 { None } else { Some(params.to_string()) }
  self.with_query(query)
}

///|
/// Joins decoded query pairs without losing duplicate keys.
pub fn format_query_pairs(pairs : Array[(String, String)]) -> String {
  URLSearchParams::from_pairs(pairs).to_string()
}

///|
/// Parses a query string and returns a sorted, encoded representation.
pub fn canonical_query(query : String) -> String {
  let params = URLSearchParams::new(query)
  params.sort()
  params.to_string()
}

///|
/// Returns the first non-empty value for a key.
pub fn first_non_empty(query : String, key : String) -> String? {
  for value in URLSearchParams::new(query).get_all(key) {
    if value != "" {
      return Some(value)
    }
  }
  None
}
