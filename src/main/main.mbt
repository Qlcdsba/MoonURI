// MoonURI executable usage demo

fn opt_str(o : Option[String]) -> String {
  match o {
    Some(s) => s
    None => "<None>"
  }
}

fn opt_int(o : Option[Int]) -> String {
  match o {
    Some(i) => i.to_string()
    None => "<None>"
  }
}

fn main {
  println("=================== MoonURI Demo ===================")
  
  // 1. Parsing a complete URI
  let uri_str = "https://user:password@example.com:443/path/to/page?query=1&var=hello%20world#section-1"
  println("Original URI String: " + uri_str)
  
  match @lib.parse(uri_str) {
    Ok(uri) => {
      println("\nParsed URI Components:")
      println("  Scheme:    " + opt_str(uri.scheme))
      match uri.authority {
        Some(auth) => {
          println("  Authority:")
          println("    UserInfo: " + opt_str(auth.userinfo))
          println("    Host:     " + auth.host)
          println("    Port:     " + opt_int(auth.port))
        }
        None => println("  Authority: None")
      }
      println("  Path:      " + uri.path)
      println("  Query:     " + opt_str(uri.query))
      println("  Fragment:  " + opt_str(uri.fragment))
      
      // JSON Serialization
      println("\nURI Serialization:")
      println("  Reconstructed String: " + uri.to_string())
      println("  JSON Representation:  " + uri.to_json().to_string())
    }
    Err(e) => println("Error parsing URI: " + e)
  }
  
  // 2. Relative URI Resolution (RFC 3986 Section 5)
  println("\n=================== Relative Resolution ===================")
  match @lib.parse("http://a/b/c/d;p?q") {
    Ok(base_uri) => {
      println("Base URI: " + base_uri.to_string())
      
      let relative_paths = [
        "g",
        "./g",
        "g/",
        "/g",
        "//g",
        "?y",
        "g?y",
        "#s",
        "g#s",
        "../g",
        "../../g",
        "../../",
      ]
      
      for rel in relative_paths {
        match base_uri.resolve_string(rel) {
          Ok(resolved) => println("  Resolve \"" + rel + "\" -> " + resolved.to_string())
          Err(e) => println("  Error resolving \"" + rel + "\": " + e)
        }
      }
    }
    Err(e) => println("Error parsing base URI: " + e)
  }
  
  // 3. URLSearchParams Demo
  println("\n=================== URLSearchParams Demo ===================")
  let query_str = "?search=MoonBit+Language&category=Wasm&search=Rust"
  println("Original Query String: " + query_str)
  
  let sp = @lib.URLSearchParams::new(query_str)
  println("\nParsed Query Parameters:")
  println("  Has 'search'? " + sp.has("search").to_string())
  println("  Get 'search': " + opt_str(sp.get("search")))
  println("  Get all 'search': " + sp.get_all("search").to_string())
  println("  Get 'category': " + opt_str(sp.get("category")))
  
  println("\nModifying Query Parameters:")
  sp.set("search", "MoonBit Compiler")
  sp.append("page", "1")
  sp.delete("category")
  println("  Modified to_string(): ?" + sp.to_string())
}
