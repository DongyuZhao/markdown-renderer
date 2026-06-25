import Foundation

/// A JSON value used by directive attributes.
@frozen public indirect enum MarkdownDirectiveAttributeValue: Equatable, Sendable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case array([MarkdownDirectiveAttributeValue])
  case object([String: MarkdownDirectiveAttributeValue])
  case null

  init(any value: Any) {
    switch value {
    case let string as String:
      self = .string(string)
    case let number as NSNumber:
      if CFGetTypeID(number) == CFBooleanGetTypeID() {
        self = .bool(number.boolValue)
      } else {
        self = .number(number.doubleValue)
      }
    case let array as [Any]:
      self = .array(array.map(MarkdownDirectiveAttributeValue.init(any:)))
    case let object as [String: Any]:
      self = .object(object.mapValues(MarkdownDirectiveAttributeValue.init(any:)))
    default:
      self = .null
    }
  }
}

public typealias MarkdownDirectiveAttributes = [String: MarkdownDirectiveAttributeValue]