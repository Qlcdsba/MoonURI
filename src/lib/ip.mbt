// IPv4 and IPv6 host syntax parser and validator (RFC 3986 Section 3.2.2)

///|
/// Validates if a string is a valid decimal octet (0-255, no leading zeros unless single "0")
fn is_dec_octet(s : String) -> Bool {
  let len = s.length()
  if len == 0 || len > 3 {
    return false
  }
  if len > 1 && s[0].to_int() == '0'.to_int() {
    return false // No leading zeros
  }
  let mut val = 0
  for i = 0; i < len; i = i + 1 {
    let c = s[i]
    if c.to_int() < '0'.to_int() || c.to_int() > '9'.to_int() {
      return false
    }
    val = val * 10 + (c.to_int() - 48)
  }
  val >= 0 && val <= 255
}

///|
/// Checks if a string is a valid IPv4 address
pub fn is_ipv4(host : String) -> Bool {
  let parts = host.split(".")
  let mut count = 0
  for _ in parts {
    count = count + 1
  }
  if count != 4 {
    return false
  }

  // Re-verify each part
  for p in host.split(".") {
    if !is_dec_octet(p.to_owned()) {
      return false
    }
  }
  true
}

///|
/// Checks if a character code is a valid hexadecimal digit
fn is_hex_digit(c : Char) -> Bool {
  let code = c.to_int()
  (code >= 48 && code <= 57) || // 0-9
  (code >= 65 && code <= 70) || // A-F
  (code >= 97 && code <= 102) // a-f
}

///|
/// Validates a 16-bit hex group (1 to 4 hex digits)
fn is_hex_group(s : String) -> Bool {
  let len = s.length()
  if len == 0 || len > 4 {
    return false
  }
  for i = 0; i < len; i = i + 1 {
    let c = s[i].to_int()
    if !((c >= '0'.to_int() && c <= '9'.to_int()) ||
      (c >= 'A'.to_int() && c <= 'F'.to_int()) ||
      (c >= 'a'.to_int() && c <= 'f'.to_int())) {
      return false
    }
  }
  true
}

///|
/// Checks if a string is a valid IPv6 address (excluding the enclosing brackets)
pub fn is_ipv6(addr : String) -> Bool {
  if addr.length() == 0 {
    return false
  }

  // Check for dual colons "::"
  let parts = addr.split("::")
  let mut double_colon_count = 0
  for _ in parts {
    double_colon_count = double_colon_count + 1
  }
  if double_colon_count > 2 {
    return false // More than one "::" is invalid
  }

  let has_double_colon = double_colon_count == 2

  // Split into left and right parts
  let mut left_str = ""
  let mut right_str = ""

  let mut idx = 0
  for p in addr.split("::") {
    if idx == 0 {
      left_str = p.to_owned()
    } else if idx == 1 {
      right_str = p.to_owned()
    }
    idx = idx + 1
  }

  // Helper to split a string by ':' and validate groups
  // Returns (number of groups, is_valid)
  // If the last group contains '.', it might be an IPv4 address (which counts as 2 groups)
  fn parse_groups(s : String) -> Result[Int, String] {
    if s.length() == 0 {
      return Ok(0)
    }
    let mut count = 0
    let mut parts_count = 0

    // Count items in split first
    for _ in s.split(":") {
      parts_count = parts_count + 1
    }

    let mut i = 0
    for p in s.split(":") {
      let is_last = i == parts_count - 1
      let p_str = p.to_owned()
      if is_last && index_of_char(p_str, '.') >= 0 {
        // Must be a valid IPv4 address
        if !is_ipv4(p_str) {
          return Err("Invalid IPv4-mapped IPv6 suffix")
        }
        count = count + 2
      } else {
        if !is_hex_group(p_str) {
          return Err("Invalid hex group")
        }
        count = count + 1
      }
      i = i + 1
    }
    Ok(count)
  }

  let left_res = parse_groups(left_str)
  let right_res = parse_groups(right_str)

  match (left_res, right_res) {
    (Ok(left_count), Ok(right_count)) => {
      let total_count = left_count + right_count
      if has_double_colon {
        total_count < 8 // Less than 8 groups if compressed
      } else {
        total_count == 8 // Exactly 8 groups if uncompressed
      }
    }
    _ => false
  }
}

///|
/// Checks if the host string is a valid IPv6 literal enclosed in brackets (e.g. "[2001:db8::1]")
pub fn is_ipv6_literal(host : String) -> Bool {
  let len = host.length()
  if len < 3 ||
    host[0].to_int() != '['.to_int() ||
    host[len - 1].to_int() != ']'.to_int() {
    return false
  }
  let addr = host[1:len - 1].to_owned()
  is_ipv6(addr)
}

///|
/// Validates if the host string is valid (either registered name, IPv4, or IPv6 literal)
pub fn is_valid_host(host : String) -> Bool {
  if is_ipv6_literal(host) {
    true
  } else if is_ipv4(host) {
    true
  } else {
    // Registered name (e.g. domain name). According to RFC 3986 Section 3.2.2,
    // it can contain unreserved characters, percent-encoded octets, and sub-delims.
    let mut i = 0
    let len = host.length()
    while i < len {
      let c = host[i].to_int()
      if c == 37 { // '%'
        if i + 2 >= len ||
          !is_hex_digit(Int::unsafe_to_char(host[i + 1].to_int())) ||
          !is_hex_digit(Int::unsafe_to_char(host[i + 2].to_int())) {
          return false
        }
        i = i + 3
      } else if is_unreserved(Int::unsafe_to_char(c)) ||
        c == 33 ||
        c == 36 ||
        c == 38 ||
        c == 39 ||
        c == 40 ||
        c == 41 || // ! $ & ' ( )
        c == 42 ||
        c == 43 ||
        c == 44 ||
        c == 59 ||
        c == 61 { // * + , ; =
        i = i + 1
      } else {
        return false // Illegal character in domain/host name
      }
    }
    true
  }
}
