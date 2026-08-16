// URI safety helpers. These functions deliberately remain policy-light: they
// inspect syntax and expose facts so an HTTP client or router can choose its
// own allow-list and network policy.

///|
/// A coarse host classification useful for request policies and telemetry.
pub enum HostKind {
  IPv4
  IPv6
  RegisteredName
  EmptyHost
} derive(Debug, Eq)

///|
/// Classifies a host spelling according to RFC 3986 authority grammar.
pub fn classify_host(host : String) -> HostKind {
  if host == "" {
    EmptyHost
  } else if is_ipv6_literal(host) {
    IPv6
  } else if is_ipv4(host) {
    IPv4
  } else {
    RegisteredName
  }
}

///|
/// Returns true for loopback IPv4, IPv6, or the conventional localhost name.
pub fn is_loopback_host(host : String) -> Bool {
  if host == "localhost" || host == "localhost." {
    return true
  }
  if host == "127.0.0.1" || host == "0.0.0.0" {
    return true
  }
  if host == "[::1]" || host == "[0:0:0:0:0:0:0:1]" {
    return true
  }
  false
}

///|
/// Returns true when the URI has an HTTP(S) scheme and an authority.
pub fn URI::is_http_url(self : URI) -> Bool {
  match (self.scheme, self.authority) {
    (Some(scheme), Some(_)) => {
      let lower = to_lowercase(scheme)
      lower == "http" || lower == "https"
    }
    _ => false
  }
}

///|
/// Returns true if the URI host is a loopback address.
pub fn URI::is_loopback(self : URI) -> Bool {
  match self.authority {
    Some(auth) => is_loopback_host(to_lowercase(auth.host))
    None => false
  }
}

///|
/// Returns a user-facing list of syntax issues; an empty list means valid.
pub fn URI::validation_issues(self : URI) -> Array[String] {
  let issues = Array::new()
  match self.scheme {
    Some(scheme) =>
      if !is_valid_scheme(scheme) {
        issues.push("scheme is not RFC 3986 compliant")
      }
    None => ()
  }
  match self.authority {
    Some(auth) => {
      if auth.host == "" {
        issues.push("authority host must not be empty")
      }
      if !is_valid_host(auth.host) {
        issues.push("authority host contains invalid characters")
      }
      match auth.port {
        Some(port) =>
          if port < 0 || port > 65535 {
            issues.push("authority port is outside 0..65535")
          }
        None => ()
      }
    }
    None => ()
  }
  for
    component in [
      self.path,
      self.query.unwrap_or(""),
      self.fragment.unwrap_or(""),
    ] {
    match percent_decode(component) {
      Ok(_) => ()
      Err(_) =>
        issues.push("component contains invalid percent-encoding or UTF-8")
    }
  }
  issues
}

///|
/// Reports whether this URI passes the library's syntax checks.
pub fn URI::is_valid(self : URI) -> Bool {
  self.validation_issues().length() == 0
}

///|
/// Removes credentials and fragments for safe structured logging.
pub fn URI::redacted(self : URI) -> String {
  self.without_userinfo().without_fragment().to_string()
}

///|
/// Produces a short normalized request target, including query but not origin.
pub fn URI::request_target(self : URI) -> String {
  let target = if self.path == "" { "/" } else { self.path }
  match self.query {
    Some(query) => target + "?" + query
    None => target
  }
}
