// URLSearchParams parser and formatter for URI Query Parameters

///|
/// Represents the query parameters of a URI
pub struct URLSearchParams {
  mut params : Array[(String, String)]
} derive(Debug, Eq)

///|
/// Parses a query string into a URLSearchParams struct
pub fn URLSearchParams::new(query_str : String) -> URLSearchParams {
  let params = Array::new()
  let mut s = query_str
  if s.has_prefix("?") {
    s = s[1:].to_owned()
  }
  if s.length() == 0 {
    return { params, }
  }

  for part in s.split("&") {
    let part_str = part.to_owned()
    if part_str.length() == 0 {
      continue
    }
    let eq_idx = index_of_char(part_str, '=')
    let (raw_key, raw_val) = if eq_idx >= 0 {
      (part_str[0:eq_idx].to_owned(), part_str[eq_idx + 1:].to_owned())
    } else {
      (part_str, "")
    }

    // Replace '+' with ' ' before percent decoding
    let key_processed = replace_plus_with_space(raw_key)
    let val_processed = replace_plus_with_space(raw_val)

    let key = match percent_decode(key_processed) {
      Ok(k) => k
      Err(_) => key_processed
    }
    let val = match percent_decode(val_processed) {
      Ok(v) => v
      Err(_) => val_processed
    }

    params.push((key, val))
  }
  { params, }
}

///|
/// Helper to replace '+' character with space
fn replace_plus_with_space(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if c == '+' {
      buf.write_char(' ')
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Gets the first value associated with the given key
pub fn URLSearchParams::get(self : URLSearchParams, key : String) -> String? {
  for pair in self.params {
    let (k, v) = pair
    if k == key {
      return Some(v)
    }
  }
  None
}

///|
/// Gets all values associated with the given key
pub fn URLSearchParams::get_all(
  self : URLSearchParams,
  key : String,
) -> Array[String] {
  let res = Array::new()
  for pair in self.params {
    let (k, v) = pair
    if k == key {
      res.push(v)
    }
  }
  res
}

///|
/// Checks if the given key exists in the parameters
pub fn URLSearchParams::has(self : URLSearchParams, key : String) -> Bool {
  for pair in self.params {
    let (k, _) = pair
    if k == key {
      return true
    }
  }
  false
}

///|
/// Appends a new key-value pair to the parameters
pub fn URLSearchParams::append(
  self : URLSearchParams,
  key : String,
  value : String,
) -> Unit {
  self.params.push((key, value))
}

///| Sets the value associated with the given key.

///|
/// If there are multiple existing values, all others are removed.
pub fn URLSearchParams::set(
  self : URLSearchParams,
  key : String,
  value : String,
) -> Unit {
  let new_params = Array::new()
  let mut set_done = false
  for pair in self.params {
    let (k, _) = pair
    if k == key {
      if !set_done {
        new_params.push((key, value))
        set_done = true
      }
    } else {
      new_params.push(pair)
    }
  }
  if !set_done {
    new_params.push((key, value))
  }
  self.params = new_params
}

///|
/// Deletes all values associated with the given key
pub fn URLSearchParams::delete(self : URLSearchParams, key : String) -> Unit {
  let new_params = Array::new()
  for pair in self.params {
    let (k, _) = pair
    if k != key {
      new_params.push(pair)
    }
  }
  self.params = new_params
}

///|
/// Converts the parameters into a query string representation (without leading '?')
pub fn URLSearchParams::to_string(self : URLSearchParams) -> String {
  let buf = StringBuilder::new()
  let mut first = true
  for pair in self.params {
    if !first {
      buf.write_char('&')
    }
    first = false
    let (k, v) = pair
    buf.write_string(percent_encode(k, true))
    buf.write_char('=')
    buf.write_string(percent_encode(v, true))
  }
  buf.to_string()
}
