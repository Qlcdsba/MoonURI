// Higher-level URI utilities for safe inspection, routing, logging, and cache keys.

///|
/// The syntactic position of a URI reference in RFC 3986.
pub enum URIReferenceKind {
  Absolute
  NetworkPath
  AbsolutePath
  RelativePath
  Empty
} derive(Debug, Eq)

///|
/// Classifies a URI reference without changing its components.
pub fn URI::kind(self : URI) -> URIReferenceKind {
  match self.scheme {
    Some(_) => Absolute
    None =>
      match self.authority {
        Some(_) => NetworkPath
        None =>
          if self.path == "" {
            Empty
          } else if self.path.has_prefix("/") {
            AbsolutePath
          } else {
            RelativePath
          }
      }
  }
}

///|
/// Returns whether this reference contains a scheme.
pub fn URI::is_absolute(self : URI) -> Bool {
  self.scheme is Some(_)
}

///|
/// Returns the normalized origin (`scheme://authority`) when available.
pub fn URI::origin(self : URI) -> String? {
  match (self.scheme, self.authority) {
    (Some(scheme), Some(authority)) =>
      Some(to_lowercase(scheme) + "://" + authority.to_string())
    _ => None
  }
}

///|
/// Returns path segments while preserving their encoded spelling.
pub fn URI::path_segments(self : URI) -> Array[String] {
  let result = Array::new()
  for segment in self.path.split("/") {
    if segment.to_owned() != "" {
      result.push(segment.to_owned())
    }
  }
  result
}

///|
/// Returns a copy with the fragment removed, useful for HTTP cache keys.
pub fn URI::without_fragment(self : URI) -> URI {
  URI::new(self.scheme, self.authority, self.path, self.query, None)
}

///|
/// Returns a copy with user information removed before logging or tracing.
pub fn URI::without_userinfo(self : URI) -> URI {
  let authority = match self.authority {
    Some(auth) => Some(Authority::new(None, auth.host, auth.port))
    None => None
  }
  URI::new(self.scheme, authority, self.path, self.query, self.fragment)
}

///|
/// Returns a copy with a query string replaced.
pub fn URI::with_query(self : URI, query : String?) -> URI {
  URI::new(self.scheme, self.authority, self.path, query, self.fragment)
}

///|
/// Returns a stable string suitable for a cache key.
pub fn URI::cache_key(self : URI) -> String {
  self.normalize().without_fragment().to_string()
}

///|
/// Returns decoded path segments when every segment is valid UTF-8.
pub fn URI::decode_path_segments(self : URI) -> Result[Array[String], String] {
  let result = Array::new()
  for segment in self.path_segments() {
    match percent_decode(segment) {
      Ok(value) => result.push(value)
      Err(error) => return Err(error)
    }
  }
  Ok(result)
}
