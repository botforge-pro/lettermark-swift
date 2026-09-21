import Foundation

/// The letters and the colour slot a thing gets when it has no picture of its own.
public enum Lettermark {

  /// The letters drawn in the square for `name`, as a reader of that writing system expects them.
  ///
  /// The result is empty when the name holds nothing drawable; the caller then paints the square
  /// and leaves it blank rather than inventing a placeholder character.
  public static func initials(of name: String) -> String {
    let normalized = name.precomposedStringWithCanonicalMapping

    var units: [String] = []
    for word in words(of: normalized) {
      guard let unit = firstSyllable(of: word) else { continue }
      units.append(upperKeepingLength(unit))
      if units.count == 2 || writesAsOneSyllableWhole(unit) {
        break
      }
    }
    if units.isEmpty {
      return firstDrawableCluster(of: normalized).precomposedStringWithCanonicalMapping
    }
    return units.joined().precomposedStringWithCanonicalMapping
  }
}

/// How many colours the caller paints, and which of them a thing is drawn on.
///
/// The colours themselves live with the rest of the design — a colour catalogue, a theme, a
/// stylesheet — and this type only says which of them to reach for.
public struct Palette: Sendable, Hashable {

  /// How many colours this palette holds.
  public let slots: Int

  /// Builds a palette of `slots` colours.
  ///
  /// A count below 1 means the code and the theme disagree, which is a broken invariant rather
  /// than a value with an answer, so it stops the program here instead of handing out a slot no
  /// colour is painted for.
  public init(slots: Int) {
    precondition(slots >= 1, "Lettermark: a palette of \(slots) colours has no slot to hand out")
    self.slots = slots
  }

  /// Which colour `id` is drawn on, from `0` to `slots - 1`.
  ///
  /// The same id always answers the same slot, so a thing keeps its colour between screens and
  /// between runs.
  public func slot(for id: Int64) -> Int {
    let slots = Int64(self.slots)
    return Int(((id % slots) + slots) % slots)
  }
}

extension Lettermark {

  fileprivate static func words(of name: String) -> [String] {
    var out: [String] = []
    var current = String.UnicodeScalarView()
    for scalar in name.unicodeScalars {
      if isWordBreak(scalar) {
        if !current.isEmpty {
          out.append(String(current))
          current = String.UnicodeScalarView()
        }
        continue
      }
      current.append(scalar)
    }
    if !current.isEmpty {
      out.append(String(current))
    }
    return out
  }

  fileprivate static func isWordBreak(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x0085, 0x00A0, 0x1680, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000:
      return true
    default:
      return (0x0009...0x000D).contains(scalar.value)
        || scalar.value == 0x0020
        || (0x2000...0x200A).contains(scalar.value)
    }
  }

  fileprivate static func firstSyllable(of word: String) -> String? {
    let clusters = Array(word)
    for (index, cluster) in clusters.enumerated() {
      guard let opener = cluster.unicodeScalars.first, opensAUnit(opener) else { continue }
      return grownIntoASyllable(String(cluster), rest: clusters[(index + 1)...])
    }
    return nil
  }

  fileprivate static func grownIntoASyllable(
    _ start: String, rest: ArraySlice<Character>
  ) -> String {
    var unit = start
    var index = rest.startIndex
    while index < rest.endIndex {
      guard let last = unit.unicodeScalars.last, isVirama(last) || isPrefixVowel(unit) else {
        return unit
      }
      unit.append(rest[index])
      index = rest.index(after: index)
    }
    return unit
  }

  fileprivate static func isPrefixVowel(_ unit: String) -> Bool {
    let scalars = Array(unit.unicodeScalars)
    guard scalars.count == 1 else { return false }
    let value = scalars[0].value
    return (0x0E40...0x0E44).contains(value) || (0x0EC0...0x0EC4).contains(value)
  }

  fileprivate static func isVirama(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x094D, 0x09CD, 0x0A4D, 0x0ACD, 0x0B4D, 0x0BCD, 0x0C4D, 0x0CCD,
      0x0D4D, 0x0DCA, 0x0F84, 0x1039, 0x17D2:
      return true
    default:
      return false
    }
  }

  fileprivate static func opensAUnit(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.properties.generalCategory {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .otherLetter, .decimalNumber:
      return true
    default:
      return false
    }
  }

  fileprivate static func writesAsOneSyllableWhole(_ unit: String) -> Bool {
    guard let first = unit.unicodeScalars.first else { return false }
    switch first.value {
    case 0x0600...0x06FF, 0x0700...0x074F, 0x0750...0x077F, 0x07C0...0x07FF,
      0x0860...0x086F, 0x08A0...0x08FF, 0xFB50...0xFDFF, 0xFE70...0xFEFF,
      0x1E900...0x1E95F,
      0x1100...0x11FF, 0x3130...0x318F, 0xA960...0xA97F, 0xAC00...0xD7FF,
      0xFFA0...0xFFDC,
      0x2E80...0x2EFF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF,
      0x20000...0x3134F,
      0x3040...0x30FF, 0x31F0...0x31FF, 0xFF66...0xFF9F,
      0x1800...0x18AF:
      return true
    default:
      return false
    }
  }

  fileprivate static func upperKeepingLength(_ unit: String) -> String {
    guard let first = unit.unicodeScalars.first else { return unit }
    if isGeorgianMkhedruli(first) { return unit }
    let uppercased = unit.uppercased()
    if uppercased.unicodeScalars.count > unit.unicodeScalars.count { return unit }
    return uppercased
  }

  fileprivate static func isGeorgianMkhedruli(_ scalar: Unicode.Scalar) -> Bool {
    (0x10D0...0x10FF).contains(scalar.value)
  }

  fileprivate static func firstDrawableCluster(of name: String) -> String {
    for cluster in name {
      guard let first = cluster.unicodeScalars.first else { continue }
      if isWordBreak(first) || isMarkOrControl(first) { continue }
      return String(cluster)
    }
    return ""
  }

  fileprivate static func isMarkOrControl(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.properties.generalCategory {
    case .nonspacingMark, .spacingMark, .enclosingMark,
      .control, .format, .surrogate, .privateUse, .unassigned:
      return true
    default:
      return false
    }
  }
}
