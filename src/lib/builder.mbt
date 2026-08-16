// Mutable builder for applications that assemble URIs from validated pieces.

///|
/// Incrementally constructs a URI while keeping component ownership explicit.
pub struct URIBuilder {
  mut scheme : String?
  mut authority : Authority?
  mut path : String
  mut query : String?
  mut fragment : String?
} derive(Debug)

///|
/// Creates an empty URI builder.
pub fn URIBuilder::new() -> URIBuilder {
  { scheme: None, authority: None, path: "", query: None, fragment: None }
}

///|
/// Starts a builder from an existing URI.
pub fn URIBuilder::from_uri(uri : URI) -> URIBuilder {
  {
    scheme: uri.scheme,
    authority: uri.authority,
    path: uri.path,
    query: uri.query,
    fragment: uri.fragment,
  }
}

///|
/// Sets the scheme.
pub fn URIBuilder::scheme(self : URIBuilder, value : String?) -> URIBuilder {
  self.scheme = value
  self
}

///|
/// Sets the authority.
pub fn URIBuilder::authority(
  self : URIBuilder,
  value : Authority?,
) -> URIBuilder {
  self.authority = value
  self
}

///|
/// Sets the host and optional port as an authority.
pub fn URIBuilder::host(
  self : URIBuilder,
  host : String,
  port? : Int,
) -> URIBuilder {
  self.authority = Some(Authority::new(None, host, port))
  self
}

///|
/// Sets the path without automatically encoding it.
pub fn URIBuilder::path(self : URIBuilder, value : String) -> URIBuilder {
  self.path = value
  self
}

///|
/// Appends one encoded-or-raw path segment with exactly one separator.
pub fn URIBuilder::append_path(
  self : URIBuilder,
  segment : String,
) -> URIBuilder {
  if self.path == "" || self.path == "/" {
    self.path = self.path + segment
  } else if self.path.has_suffix("/") {
    self.path = self.path + segment
  } else {
    self.path = self.path + "/" + segment
  }
  self
}

///|
/// Sets a raw query string without a leading question mark.
pub fn URIBuilder::query(self : URIBuilder, value : String?) -> URIBuilder {
  self.query = match value {
    Some(q) => Some(if q.has_prefix("?") { q[1:].to_owned() } else { q })
    None => None
  }
  self
}

///|
/// Sets a query parameter using decoded key/value strings.
pub fn URIBuilder::query_param(
  self : URIBuilder,
  key : String,
  value : String,
) -> URIBuilder {
  let params = URLSearchParams::new(self.query.unwrap_or(""))
  params.append(key, value)
  self.query = Some(params.to_string())
  self
}

///|
/// Sets or clears the fragment.
pub fn URIBuilder::fragment(self : URIBuilder, value : String?) -> URIBuilder {
  self.fragment = value
  self
}

///|
/// Materializes the current components.
pub fn URIBuilder::build(self : URIBuilder) -> URI {
  URI::new(self.scheme, self.authority, self.path, self.query, self.fragment)
}

///|
/// Materializes and validates the URI, returning all syntax issues.
pub fn URIBuilder::build_checked(
  self : URIBuilder,
) -> Result[URI, Array[String]] {
  let uri = self.build()
  let issues = uri.validation_issues()
  if issues.length() == 0 {
    Ok(uri)
  } else {
    Err(issues)
  }
}
