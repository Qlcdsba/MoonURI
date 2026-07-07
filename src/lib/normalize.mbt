// RFC 3986 URI Case and Percent-Encoding Normalization (Section 6)

///| Converts ASCII characters in a string to lowercase
fn to_lowercase(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    let code = c.to_int()
    if code >= 65 && code <= 90 {
      buf.write_char(Int::unsafe_to_char(code + 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///| Normalizes percent-encoding hex digits to uppercase (RFC 3986 Section 6.2.2.1)
fn normalize_percent_encoding(s : String) -> String {
  let buf = StringBuilder::new()
  let len = s.length()
  let mut i = 0
  while i < len {
    let c = s[i].to_int()
    if c == 37 && i + 2 < len { // '%'
      let h1 = s[i + 1].to_int()
      let h2 = s[i + 2].to_int()
      // Check if both are valid hex digits before converting
      let is_h1_hex = (h1 >= 48 && h1 <= 57) || (h1 >= 65 && h1 <= 70) || (h1 >= 97 && h1 <= 102)
      let is_h2_hex = (h2 >= 48 && h2 <= 57) || (h2 >= 65 && h2 <= 70) || (h2 >= 97 && h2 <= 102)
      if is_h1_hex && is_h2_hex {
        let n_h1 = if h1 >= 97 && h1 <= 102 { h1 - 32 } else { h1 }
        let n_h2 = if h2 >= 97 && h2 <= 102 { h2 - 32 } else { h2 }
        buf.write_char('%')
        buf.write_char(Int::unsafe_to_char(n_h1))
        buf.write_char(Int::unsafe_to_char(n_h2))
        i = i + 3
      } else {
        buf.write_char(Int::unsafe_to_char(c))
        i = i + 1
      }
    } else {
      buf.write_char(Int::unsafe_to_char(c))
      i = i + 1
    }
  }
  buf.to_string()
}

///| Performs syntax-based normalization on a URI (RFC 3986 Section 6.2.2)
pub fn URI::normalize(self : URI) -> URI {
  let n_scheme = match self.scheme {
    Some(s) => Some(to_lowercase(s))
    None => None
  }
  
  let n_authority = match self.authority {
    Some(auth) => {
      let n_userinfo = match auth.userinfo {
        Some(u) => Some(normalize_percent_encoding(u))
        None => None
      }
      let n_host = to_lowercase(auth.host)
      Some(Authority::new(n_userinfo, n_host, auth.port))
    }
    None => None
  }
  
  let n_path = remove_dot_segments(normalize_percent_encoding(self.path))
  
  let n_query = match self.query {
    Some(q) => Some(normalize_percent_encoding(q))
    None => None
  }
  
  let n_fragment = match self.fragment {
    Some(f) => Some(normalize_percent_encoding(f))
    None => None
  }
  
  URI::new(n_scheme, n_authority, n_path, n_query, n_fragment)
}
