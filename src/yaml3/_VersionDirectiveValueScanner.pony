
/*
 * Scan the value of VERSION-DIRECTIVE.
 *
 * Scope:
 *      %YAML   1.1     # a commentn
 *           ^^^^^^
 */
class _VersionDirectiveValueScanner is _Scanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _versionScanner: (None | _VersionDirectiveNumberScanner) = None
  var major: U16 = 0
  var minor: U16 = 0

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    let s = _VersionDirectiveNumberScanner.create(_startMark, _WhitespaceScanner~scan(this~_scanDot()))
    _versionScanner = s
    s.apply(state)

  fun ref _scanDot(state: _ScannerState): _ScanResult ? =>
    let versionScanner = _versionScanner as _VersionDirectiveNumberScanner
    major = versionScanner.value
    /* Eat '.'. */
    if not state.check('.') then
      return ScanError("while scanning a %YAML directive", _startMark, "did not find expected digit or '.' character")
    end
    state.skip()
    let s = _VersionDirectiveNumberScanner.create(_startMark, this~_scanEnd())
    _versionScanner = s
    s.apply(state)

  fun ref _scanEnd(state: _ScannerState): _ScanResult ? =>
    let versionScanner = _versionScanner as _VersionDirectiveNumberScanner
    minor = versionScanner.value
    _nextScanner.apply(state)
