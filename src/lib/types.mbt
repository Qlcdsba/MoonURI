// RFC 3986 URI and Authority types and traits

///| Represents the Authority component of a URI (RFC 3986 Section 3.2)
pub struct Authority {
  userinfo : Option[String]
  host : String
  port : Option[Int]
} derive(Debug, Eq, ToJson, FromJson)

///| Represents a complete Uniform Resource Identifier (RFC 3986 Section 3)
pub struct URI {
  scheme : Option[String]
  authority : Option[Authority]
  path : String
  query : Option[String]
  fragment : Option[String]
} derive(Debug, Eq, ToJson, FromJson)

///| Creates a new Authority component
pub fn Authority::new(
  userinfo : Option[String],
  host : String,
  port : Option[Int]
) -> Authority {
  { userinfo, host, port }
}

///| Creates a new URI component
pub fn URI::new(
  scheme : Option[String],
  authority : Option[Authority],
  path : String,
  query : Option[String],
  fragment : Option[String]
) -> URI {
  { scheme, authority, path, query, fragment }
}

///| Reconstructs the Authority component into its string representation
pub fn Authority::to_string(self : Authority) -> String {
  let buf = StringBuilder::new()
  match self.userinfo {
    Some(u) => {
      buf.write_string(u)
      buf.write_char('@')
    }
    None => ()
  }
  buf.write_string(self.host)
  match self.port {
    Some(p) => {
      buf.write_char(':')
      buf.write_string(p.to_string())
    }
    None => ()
  }
  buf.to_string()
}

///| Reconstructs the URI into its string representation (RFC 3986 Section 5.3)
pub fn URI::to_string(self : URI) -> String {
  let buf = StringBuilder::new()
  match self.scheme {
    Some(s) => {
      buf.write_string(s)
      buf.write_char(':')
    }
    None => ()
  }
  match self.authority {
    Some(auth) => {
      buf.write_string("//")
      buf.write_string(auth.to_string())
    }
    None => ()
  }
  buf.write_string(self.path)
  match self.query {
    Some(q) => {
      buf.write_char('?')
      buf.write_string(q)
    }
    None => ()
  }
  match self.fragment {
    Some(f) => {
      buf.write_char('#')
      buf.write_string(f)
    }
    None => ()
  }
  buf.to_string()
}

pub impl Show for Authority with output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for URI with output(self, logger) {
  logger.write_string(self.to_string())
}

// Package-private helpers for string search
fn index_of_char(s : String, target : Char) -> Int {
  for idx, char in s.iter2() {
    if char == target {
      return idx
    }
  }
  -1
}

fn last_index_of_char(s : String, target : Char) -> Int {
  let mut res = -1
  for idx, char in s.iter2() {
    if char == target {
      res = idx
    }
  }
  res
}
