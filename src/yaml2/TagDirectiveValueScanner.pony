
primitive _ScanWhitespace
primitive _ScanWhitespaceOrLineBreak
type _State is (None | _ScanWhitespace | _ScanWhitespaceOrLineBreak)

/*
 * Scan a YAML-DIRECTIVE or TAG-DIRECTIVE token.
 *
 * Scope:
 *      %YAML    1.1    # a commentn
 *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 *      %TAG    !yaml!  tag:yaml.org,2002:n
 *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */
class TagValueScanner
  let _startMark: YamlMark val
  var _state: _State = None
  var _tagHandleScanner: (None | _TagHandleScanner) = None
  var _tagURIScanner: (None | _TagURIScanner) = None
  var handle: (None | String) = None
  var prefix: (None | String) = None

  new create(mark: YamlMark val) =>
    _startMark = mark

  fun scan(state: _ScannerState): ScanResult =>
    match _state
    | None => _startScan(parser)
    | _ScanWhitespace => _scanWhitespace(parser)
    | _ScanWhitespaceOrLineBreak => _scanWhitespaceOrLineBreak(parser)

  fun _startScan(state: _ScannerState): ScanResult =>
    let s = _TagHandleScanner(1, _startMark)
    state.scannerStack.push(s)
    _tagHandleScanner = s
    state.scannerStack.push(_WhitespaceScanner)
    _state = _ScanWhitespace

  fun _scanWhitespace(state: _ScannerState): ScanResult =>
    /* Expect a whitespace. */
    if not state.buffer.available() then
      return ScanContinue
    end
    if not state.buffer.isBlank() then
      return ScanError("while scanning a %TAG directive", _startMark, "did not find expected whitespace")
    end
    let s = _TagURIScanner(1, None, _startMark)
    _scannerStack.push(s)
    _tagURIScanner = s
    state.scannerStack.push(_WhitespaceScanner)
    _state = _ScanWhitespaceOrLineBreak
    ScanContinue

  fun _scanWhitespaceOrLineBreak(state: _ScannerState): ScanResult =>
    /* Expect a whitespace or line break. */
    if not state.buffer.available() then
      return ScanContinue
    end
    if not state.buffer.isBlankZ() then
      return ScanError("while scanning a %TAG directive", _startMark, "did not find expected whitespace or line break")
    end
    let tagHandleScanner = try _tagHandleScanner as _TagHandleScanner end
    handle = tagHandleScanner.handle
    let tagURIScanner = try _tagURIScanner as _TagURIScanner end
    prefix = tagURIScanner.uri
    state.scannerStack.pop()
    ScanEnd
