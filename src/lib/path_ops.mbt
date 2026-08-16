// Pure path operations used by routers, resource loaders, and cache layers.

///|
/// Joins path fragments and removes duplicate separators at boundaries.
pub fn join_path(parts : Array[String]) -> String {
  let result = StringBuilder::new()
  let mut first = true
  for part in parts {
    let value = part
    if value == "" {
      continue
    }
    if first {
      result.write_string(value)
      first = false
    } else {
      let current = result.to_string()
      if current.has_suffix("/") && value.has_prefix("/") {
        result.write_string(value[1:].to_owned())
      } else if !current.has_suffix("/") && !value.has_prefix("/") {
        result.write_char('/')
        result.write_string(value)
      } else {
        result.write_string(value)
      }
    }
  }
  result.to_string()
}

///|
/// Returns the final non-empty segment of a path.
pub fn path_basename(path : String) -> String {
  let trimmed = if path.has_suffix("/") {
    path[0:path.length() - 1].to_owned()
  } else {
    path
  }
  let index = last_index_of_char(trimmed, '/')
  if index < 0 {
    trimmed
  } else {
    trimmed[index + 1:].to_owned()
  }
}

///|
/// Returns the directory portion, preserving a root slash when applicable.
pub fn path_dirname(path : String) -> String {
  let trimmed = if path.has_suffix("/") {
    path[0:path.length() - 1].to_owned()
  } else {
    path
  }
  let index = last_index_of_char(trimmed, '/')
  if index < 0 {
    ""
  } else if index == 0 {
    "/"
  } else {
    trimmed[0:index].to_owned()
  }
}

///|
/// Returns the last suffix after the final dot, excluding a leading dotfile.
pub fn path_extension(path : String) -> String? {
  let base = path_basename(path)
  let dot = last_index_of_char(base, '.')
  if dot <= 0 || dot == base.length() - 1 {
    None
  } else {
    Some(base[dot + 1:].to_owned())
  }
}

///|
/// Returns a path with its final segment replaced.
pub fn replace_basename(path : String, basename : String) -> String {
  let dirname = path_dirname(path)
  if dirname == "" {
    basename
  } else if dirname == "/" {
    "/" + basename
  } else {
    dirname + "/" + basename
  }
}

///|
/// Returns a canonical path with dot segments removed.
pub fn canonical_path(path : String) -> String {
  let result = remove_dot_segments(path)
  if result == "" && path.has_prefix("/") {
    "/"
  } else {
    result
  }
}
