// RFC 6570 URI Template Expansion

///|
/// A template variable value, which can be a single string or a list of strings
pub enum TemplateValue {
  StringValue(String)
  ListValue(Array[String])
} derive(Debug, Eq)

///|
/// Expand a simple RFC 6570 URI Template (Level 1)
/// Only supports simple string expansion for `{var}`
pub fn expand_template(
  template : String,
  variables : Map[String, TemplateValue],
) -> String {
  let buf = StringBuilder::new()
  let len = template.length()
  let mut i = 0

  while i < len {
    let c = template[i]
    if c == '{'.to_int().to_uint16() || c.to_int() == 123 {
      // Find the closing brace
      let mut j = i + 1
      let mut found_close = false
      while j < len {
        if template[j].to_int() == 125 { // '}'
          found_close = true
          break
        }
        j += 1
      }

      if found_close {
        let var_name = template[i + 1:j].to_owned()
        match variables.get(var_name) {
          Some(StringValue(val)) =>
            // Percent-encode the expanded value
            buf.write_string(percent_encode(val, true))
          Some(ListValue(arr)) => {
            let mut first = true
            for item in arr {
              if !first {
                buf.write_char(',')
              }
              first = false
              buf.write_string(percent_encode(item, true))
            }
          }
          None => ()
        }
        i = j + 1
      } else {
        // No closing brace, treat as literal
        buf.write_char(Int::unsafe_to_char(c.to_int()))
        i += 1
      }
    } else {
      buf.write_char(Int::unsafe_to_char(c.to_int()))
      i += 1
    }
  }

  buf.to_string()
}
