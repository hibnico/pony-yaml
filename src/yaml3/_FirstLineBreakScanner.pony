
class _FirstLineBreakScanner

  var _scalarBlanks: (None | _ScalarBlanks trn)
  var _nextScanner: _Scanner

  new create(scalarBlanks: _ScalarBlanks trn, nextScanner: _Scanner) =>
    _scalarBlanks = scalarBlanks
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this)
    end
    /* Check if it is a first line break. */
    if not (_scalarBlanks as _ScalarBlanks trn).leadingBlank then
      ((_scalarBlanks as _ScalarBlanks trn).whitespaces as String trn).clear()
      match state.readLine(((_scalarBlanks as _ScalarBlanks trn).leadingBreak = None) as String trn^)
      | let e: ScanError => return e
      | let s: String trn => (_scalarBlanks as _ScalarBlanks trn).leadingBreak = consume s
      else
        error
      end
      (_scalarBlanks as _ScalarBlanks trn).leadingBlank = true
    else
      match state.readLine(((_scalarBlanks as _ScalarBlanks trn).trailingBreaks = None) as String trn^)
      | let e: ScanError => return e
      | let s: String trn => (_scalarBlanks as _ScalarBlanks trn).trailingBreaks = consume s
      else
        error
      end
    end
    nextScanner.apply(state)
