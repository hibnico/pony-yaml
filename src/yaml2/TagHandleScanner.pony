
primitive _ScanWhitespace
primitive _ScanWhitespaceOrLineBreak
type _State is (None | _ScanAlpha | _ScanWhitespaceOrLineBreak)

/*
 * Scan a tag handle.
 */
class _TagHandleScanner is _Scanner
  let _directive: Boolean
  let _startMark: YamlMark val
  var _state: _State = None
  var handle: String = String.create()

  new create(directive: Boolean, mark: YamlMark val) =>
    _directive = directive
    _startMark = mark

  fun scan(state: _ScannerState): ScanResult =>
    match _state
    | None => _startScan(state)
    | _ScanAlpha => _scanAlpha(state)

  fun _startScan(state: _ScannerState): ScanResult =>
    /* Check the initial '!' character. */
    if not state.buffer.available() then
      return ScanContinue
    end
    if not state.buffer.check('!') then
      return ScanError(if _directive then "while scanning a tag directive" else "while scanning a tag" end,
                _startMark, "did not find expected '!'")
    end
    /* Copy the '!' character. */
    handle.push('!')
    state.skip()
    _state = _ScanAlpha
    ScanContinue

  fun _scanAlpha(state: _ScannerState): ScanResult =>
    /* Copy all subsequent alphabetical and numerical characters. */
    if not state.buffer.available() then
      return ScanContinue
    end
    while state.buffer.isAlpha() do
      state.read(handle)
      if not state.buffer.available() then
        return ScanContinue
      end
    end

    /* Check if the trailing character is '!' and copy it. */
    if state.buffer.check('!') then
      handle.push('!')
      state.skip()
    else
      /*
       * It's either the '!' tag or not really a tag handle.  If it's a %TAG
       * directive, it's an error.  If it's a tag token, it must be a part of
       * URI.
       */

      if (_directive and not (handle(0) == '!' and handle(1) == '\0')) then
        return ScanError("while parsing a tag directive", _startMark, "did not find expected '!'")
      end
    end
    parser.scannerStack.pop()
    ScanDone
