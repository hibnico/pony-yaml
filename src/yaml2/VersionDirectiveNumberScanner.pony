

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
  var value: U16 = 0
  var length: USize = 0

  new create(mark: YamlMark val) =>
    _startMark = mark

  fun scan(state: _ScannerState): ScanResult =>
    /* Repeat while the next character is digit. */
    if not state.buffer.available() then
      return ScanContinue
    end
    while state.buffer.isDigit() do
      /* Check if the number is too long. */
      length = length + 1
      if length > MAX_NUMBER_LENGTH then
        return ScanError("while scanning a %YAML directive", _startMark, "found extremely long version number")
      end
      value = value * 10 + buffer.asDigit()
      state.skip()
      if not state.buffer.available() then
        return ScanContinue
      end
    end
    /* Check if the number was present. */
    if length == 0 then
      return ScanError("while scanning a %YAML directive", _startMark, "did not find expected version number")
    end
    state.scannerStack.pop()
    ScanDone
