
class _EOLScanner
  fun ref scan(startMark: YamlMark val, errorContext: String, nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    /* Check if we are at the end of the line. */
    if not state.isBreakEOF() then
      return ScanError(errorContext, startMark, "did not find expected comment or line break")
    end
    this._eatLineBreak(nextScanner, state)

  fun ref _eatLineBreak(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    /* Eat a line break. */
    if state.isBreak() then
      if not state.available(2) then
        return ScanPaused(this~_eatLineBreak(nextScanner))
      end
      state.skipLine()
    end
    nextScanner.apply(state)
