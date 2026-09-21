import Foundation
import Testing

struct CorpusSyncTests {

  static let leading = URL(
    string: "https://raw.githubusercontent.com/botforge-pro/lettermark/main/cases.yaml")!

  @Test
  func theCopyIsWhatTheLeadingRepositoryHolds() async throws {
    let (published, response) = try await URLSession.shared.data(from: CorpusSyncTests.leading)
    let status = try #require(response as? HTTPURLResponse).statusCode
    try #require(
      status == 200,
      "the leading corpus answered \(status), so this run proves nothing about the copy")

    let url = try #require(Bundle.module.url(forResource: "cases", withExtension: "yaml"))
    let carried = try Data(contentsOf: url)

    #expect(
      carried == published,
      """
      the copy of cases.yaml here is not the one at \(CorpusSyncTests.leading): a case added to \
      the contract and never copied leaves this port on its old behaviour with every test green. \
      Run `make sync-corpus`.
      """)
  }
}
