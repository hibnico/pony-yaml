
class _AnchorScanner is _Scanner
  let _tokenConstructor: {(YamlMark val, YamlMark val, String val): _YAMLToken} val
  let _errorName: String
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _anchor: (None | String iso) = recover String.create() end
  var _length: USize = 0

  new create(tokenConstructor: {(YamlMark val, YamlMark val, String val): _YAMLToken} val, errorName: String,
             startMark: YamlMark val, nextScanner: _Scanner) =>
    _tokenConstructor = tokenConstructor
    _errorName = errorName
    _startMark = startMark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Eat the indicator character. */
    state.skip()
    this._scanAnchor(state)

  fun ref _scanAnchor(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this~_scanAnchor())
    end
    while state.isAlpha() do
      match state.read((_anchor = None) as String iso^)
      | let s: String iso => _anchor = consume s
      | let e: ScanError => return e
      end
      _length = _length + 1
      if not state.available() then
        return ScanPaused(this~_scanAnchor())
      end
    end
    if ((_length == 0) or not (state.isBlankZ() or state.check('?')
                or state.check(':') or state.check(',')
                or state.check(']') or state.check('}')
                or state.check('%') or state.check('@')
                or state.check('`'))) then
        return ScanError("while scanning an " + _errorName, _startMark, "did not find expected alphabetic or numeric character")
    end
    let endMark = state.mark.clone()
    /* Create a token. */
    state.emitToken(_tokenConstructor(_startMark, endMark, (_anchor = None) as String iso^))
    _nextScanner.apply(state)
