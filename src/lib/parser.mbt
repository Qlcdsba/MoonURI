// RFC 3986 URI parsing implementation

///| Helper to find the index of a character before encountering any stop characters
fn find_char_before(s : String, c : Char, stop_chars : Array[Char]) -> Int {
  let len = s.length()
  for i = 0; i < len; i = i + 1 {
    let curr = s[i].to_int()
    if curr == c.to_int() {
      return i
    }
    // Check if it's a stop character
    let mut is_stop = false
    for sc in stop_chars {
      if curr == sc.to_int() {
        is_stop = true
        break
      }
    }
    if is_stop {
      return -1
    }
  }
  -1
}

///| Helper to find the index of the first character from a list
fn find_first_of(s : String, chars : Array[Char]) -> Int {
  let len = s.length()
  for i = 0; i < len; i = i + 1 {
    let curr = s[i].to_int()
    for c in chars {
      if curr == c.to_int() {
        return i
      }
    }
  }
  -1
}

///| Validates if a string is a valid scheme (RFC 3986 Section 3.1)
fn is_valid_scheme(s : String) -> Bool {
  let len = s.length()
  if len == 0 {
    return false
  }
  let first = s[0].to_int()
  // Must start with a letter
  if !((first >= 'A'.to_int() && first <= 'Z'.to_int()) || (first >= 'a'.to_int() && first <= 'z'.to_int())) {
    return false
  }
  for i = 1; i < len; i = i + 1 {
    let c = s[i].to_int()
    if !((c >= 'A'.to_int() && c <= 'Z'.to_int()) || (c >= 'a'.to_int() && c <= 'z'.to_int()) || (c >= '0'.to_int() && c <= '9'.to_int()) ||
         c == '+'.to_int() || c == '-'.to_int() || c == '.'.to_int()) {
      return false
    }
  }
  true
}

///| Helper to parse a port string to an integer
fn parse_port(s : String) -> Result[Int, String] {
  let len = s.length()
  if len == 0 {
    return Err("Port number cannot be empty")
  }
  let mut val = 0
  for i = 0; i < len; i = i + 1 {
    let c = s[i].to_int()
    if c < '0'.to_int() || c > '9'.to_int() {
      return Err("Invalid digit in port: " + s)
    }
    val = val * 10 + (c - 48)
  }
  Ok(val)
}

///| Helper to parse the authority string (RFC 3986 Section 3.2)
fn parse_authority(s : String) -> Result[Authority, String] {
  let mut userinfo : Option[String] = None
  let mut host_port = s
  
  // Find userinfo component
  let at_idx = index_of_char(s, '@')
  if at_idx >= 0 {
    userinfo = Some(s[0:at_idx].to_owned())
    host_port = s[at_idx + 1:].to_owned()
  }
  
  let mut host = ""
  let mut port : Option[Int] = None
  
  // Find host and port components
  if host_port.has_prefix("[") {
    // IPv6 literal host (bracketed)
    let bracket_end = index_of_char(host_port, ']')
    if bracket_end < 0 {
      return Err("Missing closing bracket in IPv6 host: " + host_port)
    }
    host = host_port[0:bracket_end + 1].to_owned()
    
    let remaining = host_port[bracket_end + 1:].to_owned()
    if remaining.length() > 0 {
      if !remaining.has_prefix(":") {
        return Err("Invalid characters after IPv6 bracket: " + remaining)
      }
      let port_str = remaining[1:].to_owned()
      let parsed_port = match parse_port(port_str) {
        Ok(p) => p
        Err(e) => return Err(e)
      }
      port = Some(parsed_port)
    }
  } else {
    // IPv4 or Registered name host
    let colon_idx = last_index_of_char(host_port, ':')
    if colon_idx >= 0 {
      host = host_port[0:colon_idx].to_owned()
      let port_str = host_port[colon_idx + 1:].to_owned()
      let parsed_port = match parse_port(port_str) {
        Ok(p) => p
        Err(e) => return Err(e)
      }
      port = Some(parsed_port)
    } else {
      host = host_port
    }
  }
  
  if !is_valid_host(host) {
    return Err("Invalid host syntax: " + host)
  }
  
  Ok(Authority::new(userinfo, host, port))
}

///| Parses a URI or URI-reference string into a URI struct (RFC 3986 Section 3)
pub fn parse(s : String) -> Result[URI, String] {
  let mut remaining = s
  
  // 1. Parse Scheme
  let mut scheme : Option[String] = None
  let colon_idx = find_char_before(remaining, ':', ['/', '?', '#'])
  if colon_idx >= 0 {
    let sch_candidate = remaining[0:colon_idx].to_owned()
    if is_valid_scheme(sch_candidate) {
      scheme = Some(sch_candidate)
      remaining = remaining[colon_idx + 1:].to_owned()
    }
  }
  
  // 2. Parse Authority
  let mut authority : Option[Authority] = None
  if remaining.has_prefix("//") {
    remaining = remaining[2:].to_owned()
    let end_auth_idx = find_first_of(remaining, ['/', '?', '#'])
    let auth_str = if end_auth_idx >= 0 {
      let r = remaining[0:end_auth_idx].to_owned()
      remaining = remaining[end_auth_idx:].to_owned()
      r
    } else {
      let r = remaining
      remaining = ""
      r
    }
    let parsed_auth = match parse_authority(auth_str) {
      Ok(auth) => auth
      Err(e) => return Err(e)
    }
    authority = Some(parsed_auth)
  }
  
  // 3. Parse Path, Query, Fragment
  let q_idx = index_of_char(remaining, '?')
  let f_idx = index_of_char(remaining, '#')
  
  let (path, query, fragment) = if f_idx >= 0 {
    let frag = Some(remaining[f_idx + 1:].to_owned())
    let path_and_query = remaining[0:f_idx].to_owned()
    if q_idx >= 0 && q_idx < f_idx {
      (path_and_query[0:q_idx].to_owned(), Some(path_and_query[q_idx + 1:].to_owned()), frag)
    } else {
      (path_and_query, None, frag)
    }
  } else {
    if q_idx >= 0 {
      (remaining[0:q_idx].to_owned(), Some(remaining[q_idx + 1:].to_owned()), None)
    } else {
      (remaining, None, None)
    }
  }
  
  Ok(URI::new(scheme, authority, path, query, fragment))
}
