# Changelog

## 0.2.0

### Added

- The Swift port. `Lettermark.initials(of:)` gives the letters drawn in a
  square for a thing with no picture, and `Palette(slots:).slot(for:)` gives
  which of your colours it is drawn on.

  ```swift
  let letters = Lettermark.initials(of: name)

  let marks = Palette(slots: 12)  // however many colours your theme paints
  let slot = marks.slot(for: id)  // 0 … marks.slots - 1
  ```

  The first release is 0.2.0 rather than 0.1.0 because the ports share their
  first two numbers: this one answers the same rules as lettermark 0.2.0, and
  a matching `0.2` says the behaviour is the same wherever you read it.

- A copy of `cases.yaml`, the contract, and a test that compares it with the
  leading repository byte for byte. Without the network that test fails rather
  than passing quietly, because a corpus nobody could read proves nothing.
