// Percent encoding and decoding (RFC 3986 and UTF-8 compliant)

///| Checks if a character is "unreserved" according to RFC 3986 Section 2.3
pub fn is_unreserved(c : Char) -> Bool {
  let code = c.to_int()
  (code >= 65 && code <= 90) || // A-Z
  (code >= 97 && code <= 122) || // a-z
  (code >= 48 && code <= 57) || // 0-9
  c == '-' ||
  c == '.' ||
  c == '_' ||
  c == '~'
}

///| Helper to convert a Char to its UTF-8 byte representation
fn char_to_utf8(c : Char) -> Array[Int] {
  let code = c.to_int()
  if code <= 0x7F {
    [code]
  } else if code <= 0x7FF {
    [
      (code >> 6) | 0xC0,
      (code & 0x3F) | 0x80,
    ]
  } else if code <= 0xFFFF {
    [
      (code >> 12) | 0xE0,
      ((code >> 6) & 0x3F) | 0x80,
      (code & 0x3F) | 0x80,
    ]
  } else {
    [
      (code >> 18) | 0xF0,
      ((code >> 12) & 0x3F) | 0x80,
      ((code >> 6) & 0x3F) | 0x80,
      (code & 0x3F) | 0x80,
    ]
  }
}

///| Helper to parse a single hex char to its integer value (0-15)
fn hex_val(c : Char) -> Result[Int, String] {
  let code = c.to_int()
  if code >= 48 && code <= 57 {
    Ok(code - 48) // 0-9
  } else if code >= 65 && code <= 70 {
    Ok(code - 65 + 10) // A-F
  } else if code >= 97 && code <= 102 {
    Ok(code - 97 + 10) // a-f
  } else {
    Err("Invalid hex character: " + c.to_string())
  }
}

///| Helper to convert an integer to its hex character representation
fn hex_char(v : Int) -> Char {
  if v < 10 {
    Int::unsafe_to_char(48 + v)
  } else {
    Int::unsafe_to_char(65 + v - 10)
  }
}

///| Encodes a string using percent-encoding.
///| If `encode_all` is true, encodes everything except RFC 3986 unreserved chars.
///| If `encode_all` is false, encodes only characters that are invalid in a URI.
pub fn percent_encode(s : String, encode_all : Bool) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if is_unreserved(c) {
      buf.write_char(c)
    } else if !encode_all && (
      c == ':' || c == '/' || c == '?' || c == '#' || c == '[' || c == ']' || c == '@' ||
      c == '!' || c == '$' || c == '&' || c == '\'' || c == '(' || c == ')' || c == '*' ||
      c == '+' || c == ',' || c == ';' || c == '='
    ) {
      // Keep reserved characters if encode_all is false
      buf.write_char(c)
    } else {
      let bytes = char_to_utf8(c)
      for b in bytes {
        buf.write_char('%')
        buf.write_char(hex_char(b >> 4))
        buf.write_char(hex_char(b & 0x0F))
      }
    }
  }
  buf.to_string()
}

///| Decodes a percent-encoded UTF-8 string.
pub fn percent_decode(s : String) -> Result[String, String] {
  let bytes = Array::new()
  let len = s.length()
  let mut i = 0
  
  while i < len {
    let c = s[i].to_int()
    if c == 37 { // '%'
      if i + 2 >= len {
        return Err("Incomplete percent-encoding sequence at end of string")
      }
      let h1 = s[i + 1].to_int()
      let h2 = s[i + 2].to_int()
      let val1 = match hex_val(Int::unsafe_to_char(h1)) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      let val2 = match hex_val(Int::unsafe_to_char(h2)) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      bytes.push((val1 << 4) | val2)
      i += 3
    } else {
      bytes.push(c)
      i += 1
    }
  }
  
  // Now decode the UTF-8 byte array into a String
  utf8_bytes_to_string(bytes)
}

///| Decodes an array of UTF-8 bytes into a String.
fn utf8_bytes_to_string(bytes : Array[Int]) -> Result[String, String] {
  let buf = StringBuilder::new()
  let len = bytes.length()
  let mut i = 0
  
  while i < len {
    let b1 = bytes[i]
    if b1 < 0x80 {
      buf.write_char(Int::unsafe_to_char(b1))
      i += 1
    } else if (b1 & 0xE0) == 0xC0 {
      if i + 1 >= len {
        return Err("Truncated 2-byte UTF-8 sequence")
      }
      let b2 = bytes[i + 1]
      if (b2 & 0xC0) != 0x80 {
        return Err("Invalid UTF-8 continuation byte in 2-byte sequence")
      }
      let code = ((b1 & 0x1F) << 6) | (b2 & 0x3F)
      buf.write_char(Int::unsafe_to_char(code))
      i += 2
    } else if (b1 & 0xF0) == 0xE0 {
      if i + 2 >= len {
        return Err("Truncated 3-byte UTF-8 sequence")
      }
      let b2 = bytes[i + 1]
      let b3 = bytes[i + 2]
      if (b2 & 0xC0) != 0x80 || (b3 & 0xC0) != 0x80 {
        return Err("Invalid UTF-8 continuation byte in 3-byte sequence")
      }
      let code = ((b1 & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
      buf.write_char(Int::unsafe_to_char(code))
      i += 3
    } else if (b1 & 0xF8) == 0xF0 {
      if i + 3 >= len {
        return Err("Truncated 4-byte UTF-8 sequence")
      }
      let b2 = bytes[i + 1]
      let b3 = bytes[i + 2]
      let b4 = bytes[i + 3]
      if (b2 & 0xC0) != 0x80 || (b3 & 0xC0) != 0x80 || (b4 & 0xC0) != 0x80 {
        return Err("Invalid UTF-8 continuation byte in 4-byte sequence")
      }
      let code = ((b1 & 0x07) << 18) | ((b2 & 0x3F) << 12) | ((b3 & 0x3F) << 6) | (b4 & 0x3F)
      buf.write_char(Int::unsafe_to_char(code))
      i += 4
    } else {
      return Err("Invalid UTF-8 leading byte: " + b1.to_string())
    }
  }
  Ok(buf.to_string())
}
