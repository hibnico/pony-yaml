
primitive _ScanDot
primitive _ScanEnd
type _State is (None | _ScanDot | _ScanEnd)

/*
 * Scan the value of VERSION-DIRECTIVE.
 *
 * Scope:
 *      %YAML   1.1     # a commentn
 *           ^^^^^^
 */
class _VersionDirectiveValueScanner is _Scanner
  let _startMark: YamlMark val
  var _state: _State = None
  var _versionScanner: (None | _VersionDirectiveNumberScanner) = None
  var major: U16 = 0
  var minor: U16 = 0

  new create(mark: YamlMark val) =>
    _startMark = mark

  fun scan(state: _ScannerState): ScanResult =>
    match _state
    | None => _startScan(state)
    | _ScanDot => _scanDot(state)
    | _ScanEnd => _scanEnd(state)

  fun _startScan(state: _ScannerState): ScanResult =>
    let s = _VersionDirectiveNumberScanner.create(_startMark)
    state.scannerStack.push(s)
    _versionScanner = s
    state.scannerStack.push(_WhitespaceScanner)
    _state = _ScanDot
    ScanContinue

  fun _scanDot(state: _ScannerState): ScanResult =>
    let versionScanner = try _versionScanner as _VersionDirectiveNumberScanner end
    major = versionScanner.value
    /* Eat '.'. */
    if not state.buffer.check('.') then
      return ScanError("while scanning a %YAML directive", _startMark, "did not find expected digit or '.' character")
    end
    state.skip()
    let s = _VersionDirectiveNumberScanner.create(_startMark)
    state.scannerStack.push(s)
    _versionScanner = s
    _state = _ScanEnd
    ScanContinue

  fun _scanEnd(state: _ScannerState): ScanResult =>
    let versionScanner = try _versionScanner as VersionDirectiveNumberScanner end
    minor = versionScanner.value
    state.scannerStack.pop()
    ScanDone
