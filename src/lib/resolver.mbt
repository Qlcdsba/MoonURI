// RFC 3986 URI Relative Resolution and Path Normalization

///| Removes dot segments (. and ..) from a path string (RFC 3986 Section 5.2.4)
pub fn remove_dot_segments(path : String) -> String {
  let mut input = path
  let mut output = ""
  
  while input.length() > 0 {
    if input.has_prefix("../") {
      input = input[3:].to_owned()
    } else if input.has_prefix("./") {
      input = input[2:].to_owned()
    } else if input.has_prefix("/./") {
      input = "/" + input[3:].to_owned()
    } else if input == "/." {
      input = "/"
    } else if input.has_prefix("/../") {
      input = "/" + input[4:].to_owned()
      output = remove_last_segment(output)
    } else if input == "/.." {
      input = "/"
      output = remove_last_segment(output)
    } else if input == "." || input == ".." {
      input = ""
    } else {
      // Move one segment from input to output
      let mut end = 0
      if input.has_prefix("/") {
        end = 1
      }
      let len = input.length()
      while end < len && input[end].to_int() != '/'.to_int() {
        end = end + 1
      }
      let segment = input[0:end].to_owned()
      output = output + segment
      input = input[end:].to_owned()
    }
  }
  output
}

///| Helper to remove the last segment of a path for dot segment resolution
fn remove_last_segment(s : String) -> String {
  let last_slash = last_index_of_char(s, '/')
  if last_slash >= 0 {
    s[0:last_slash].to_owned()
  } else {
    ""
  }
}

///| Helper to merge target path with base path (RFC 3986 Section 5.2.3)
fn merge_paths(base_path : String, ref_path : String, base_has_auth : Bool) -> String {
  if base_has_auth && base_path.length() == 0 {
    "/" + ref_path
  } else {
    let last_slash = last_index_of_char(base_path, '/')
    if last_slash >= 0 {
      base_path[0:last_slash + 1].to_owned() + ref_path
    } else {
      ref_path
    }
  }
}

///| Resolves a relative URI reference against a base URI (RFC 3986 Section 5.2.2)
pub fn URI::resolve(self : URI, relative : URI) -> URI {
  let (t_scheme, t_authority, t_path, t_query) = match relative.scheme {
    Some(rel_sch) => {
      (Some(rel_sch), relative.authority, remove_dot_segments(relative.path), relative.query)
    }
    None => {
      match relative.authority {
        Some(rel_auth) => {
          (self.scheme, Some(rel_auth), remove_dot_segments(relative.path), relative.query)
        }
        None => {
          if relative.path == "" {
            let q = if relative.query is None { self.query } else { relative.query }
            (self.scheme, self.authority, self.path, q)
          } else {
            let merged = if relative.path.has_prefix("/") {
              relative.path
            } else {
              let has_auth = match self.authority {
                Some(_) => true
                None => false
              }
              merge_paths(self.path, relative.path, has_auth)
            }
            (self.scheme, self.authority, remove_dot_segments(merged), relative.query)
          }
        }
      }
    }
  }
  
  URI::new(t_scheme, t_authority, t_path, t_query, relative.fragment)
}

///| Resolves a relative URI string against this base URI
pub fn URI::resolve_string(self : URI, relative_str : String) -> Result[URI, String] {
  match parse(relative_str) {
    Ok(parsed) => Ok(self.resolve(parsed))
    Err(e) => Err(e)
  }
}
