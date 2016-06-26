
class _FirstLineBreakScanner

  var scalarBlanks: (None | _ScalarBlanks iso)
  var _nextScanner: _Scanner

  new create(scalarBlanks': _ScalarBlanks iso, nextScanner: _Scanner) =>
    scalarBlanks = consume scalarBlanks'
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this)
    end
    /* Check if it is a first line break. */
    if not (scalarBlanks as _ScalarBlanks iso).leadingBlank then
      ((scalarBlanks as _ScalarBlanks iso).whitespaces as String iso).clear()
      match state.readLine(((scalarBlanks as _ScalarBlanks iso).leadingBreak = None) as String iso^)
      | let e: ScanError => return e
      | let s: String iso => (scalarBlanks as _ScalarBlanks iso).leadingBreak = consume s
      else
        error
      end
      (scalarBlanks as _ScalarBlanks iso).leadingBlank = true
    else
      match state.readLine(((scalarBlanks as _ScalarBlanks iso).trailingBreaks = None) as String iso^)
      | let e: ScanError => return e
      | let s: String iso => (scalarBlanks as _ScalarBlanks iso).trailingBreaks = consume s
      else
        error
      end
    end
    _nextScanner.apply(state)
