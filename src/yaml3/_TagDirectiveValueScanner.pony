
/*
 * Scan a YAML-DIRECTIVE or TAG-DIRECTIVE token.
 *
 * Scope:
 *      %YAML    1.1    # a commentn
 *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 *      %TAG    !yaml!  tag:yaml.org,2002:n
 *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */
class _TagDirectiveValueScanner is _Scanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _tagHandleScanner: (None | _TagHandleScanner) = None
  var _tagURIScanner: (None | _TagURIScanner) = None
  var handle: (None | String val) = None
  var prefix: (None | String val) = None

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    let s = _TagHandleScanner.create(true, _startMark, this~_scanWhitespace())
    _tagHandleScanner = s
    s.apply(state)

  fun ref _scanWhitespace(state: _ScannerState): _ScanResult ? =>
    /* Expect a whitespace. */
    if not state.available() then
      return ScanPaused(this~_scanWhitespace())
    end
    if not state.isBlank() then
      return ScanError("while scanning a %TAG directive", _startMark, "did not find expected whitespace")
    end
    let s = _TagURIScanner.create(true, None, _startMark, this~_scanWhitespaceOrLineBreak())
    _tagURIScanner = s
    s.apply(state)

  fun ref _scanWhitespaceOrLineBreak(state: _ScannerState): _ScanResult ? =>
    /* Expect a whitespace or line break. */
    if not state.available() then
      return ScanPaused(this~_scanWhitespaceOrLineBreak())
    end
    if not state.isBlankZ() then
      return ScanError("while scanning a %TAG directive", _startMark, "did not find expected whitespace or line break")
    end
    let tagHandleScanner = _tagHandleScanner as _TagHandleScanner
    handle = (tagHandleScanner.handle = None) as String^
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    prefix = (tagURIScanner.uri = None) as String^
    _nextScanner.apply(state)
