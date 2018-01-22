import Foundation

// from https://github.com/vapor/leaf/blob/master/Sources/Leaf/HTMLEscape.swift

extension String {
  var htmlEscaped: String {
    return replacingOccurrences(of: "&", with: "&amp;")
          .replacingOccurrences(of: "\"", with: "&quot;")
          .replacingOccurrences(of: "'", with: "&#39;")
          .replacingOccurrences(of: "<", with: "&lt;")
          .replacingOccurrences(of: ">", with: "&gt;")
  }
}
