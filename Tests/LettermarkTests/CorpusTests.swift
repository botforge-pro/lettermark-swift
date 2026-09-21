import Foundation
import SwiftEmbed
import Testing

@testable import Lettermark

struct Corpus: Decodable {
  let version: Int
  let initials: [InitialsCase]
  let slot: [SlotCase]

  static var loaded: Corpus {
    Embedded.getYAML(Bundle.module, path: "cases.yaml")
  }
}

struct InitialsCase: Decodable, CustomTestStringConvertible {
  let name: String
  let expect: String
  let expectCodepoints: String?
  let label: String

  enum CodingKeys: String, CodingKey {
    case label = "case"
    case name
    case expect
    case expectCodepoints = "expect_codepoints"
  }

  var testDescription: String { label }
}

struct SlotCase: Decodable, CustomTestStringConvertible {
  let id: Int64
  let slots: Int
  let expect: Int
  let label: String

  enum CodingKeys: String, CodingKey {
    case label = "case"
    case id
    case slots
    case expect
  }

  var testDescription: String { label }
}

struct CorpusTests {

  @Test(arguments: Corpus.loaded.initials)
  func lettersTheCorpusNames(_ one: InitialsCase) {
    let got = Lettermark.initials(of: one.name)
    #expect(got == one.expect, "\(one.label): \(one.name)")

    if let codepoints = one.expectCodepoints {
      #expect(
        codepoints == CorpusTests.codepoints(of: got),
        """
        the letters compare equal but are written differently, which Swift's canonical \
        equivalence hides and a port that skips normalising would also pass
        """
      )
    }
  }

  @Test(arguments: Corpus.loaded.slot)
  func slotsTheCorpusNames(_ one: SlotCase) {
    let palette = Palette(slots: one.slots)
    #expect(palette.slots == one.slots)
    #expect(palette.slot(for: one.id) == one.expect, "\(one.label)")
  }

  @Test
  func theCorpusArrivedWhole() {
    #expect(Corpus.loaded.version == 2)
    #expect(!Corpus.loaded.initials.isEmpty, "the corpus is the contract and it came back empty")
    #expect(!Corpus.loaded.slot.isEmpty, "the corpus is the contract and it came back empty")
  }

  static func codepoints(of text: String) -> String {
    text.unicodeScalars
      .map { String(format: "%04X", $0.value) }
      .joined(separator: " ")
  }
}
