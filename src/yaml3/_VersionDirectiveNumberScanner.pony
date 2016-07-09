
/*
 * Scan the version number of VERSION-DIRECTIVE.
 *
 * Scope:
 *      %YAML   1.1     # a commentn
 *              ^
 *      %YAML   1.1     # a commentn
 *                ^
 */
class _VersionDirectiveNumberScanner is _Scanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var value: U16 = 0
  var length: USize = 0

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Repeat while the next character is digit. */
    if not state.available() then
      return ScanPaused(this)
    end
    while state.isDigit() do
      /* Check if the number is too long. */
      length = length + 1
      if length > 256 then
        return ScanError("while scanning a %YAML directive", _startMark, "found extremely long version number")
      end
      value = (value * 10) + state.asDigit().u16()
      state.skip()
      if not state.available() then
        return ScanPaused(this)
      end
    end
    /* Check if the number was present. */
    if length == 0 then
      return ScanError("while scanning a %YAML directive", _startMark, "did not find expected version number")
    end
    _nextScanner.apply(state)
