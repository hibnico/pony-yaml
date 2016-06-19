
class _FirstLineBreakScanner

  var scalarBlanks: (None | _ScalarBlanks trn)
  var _nextScanner: _Scanner

  new create(scalarBlanks': _ScalarBlanks trn, nextScanner: _Scanner) =>
    scalarBlanks = consume scalarBlanks'
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this)
    end
    /* Check if it is a first line break. */
    if not (scalarBlanks as _ScalarBlanks trn).leadingBlank then
      ((scalarBlanks as _ScalarBlanks trn).whitespaces as String trn).clear()
      match state.readLine(((scalarBlanks as _ScalarBlanks trn).leadingBreak = None) as String trn^)
      | let e: ScanError => return e
      | let s: String trn => (scalarBlanks as _ScalarBlanks trn).leadingBreak = consume s
      else
        error
      end
      (scalarBlanks as _ScalarBlanks trn).leadingBlank = true
    else
      match state.readLine(((scalarBlanks as _ScalarBlanks trn).trailingBreaks = None) as String trn^)
      | let e: ScanError => return e
      | let s: String trn => (scalarBlanks as _ScalarBlanks trn).trailingBreaks = consume s
      else
        error
      end
    end
    _nextScanner.apply(state)
