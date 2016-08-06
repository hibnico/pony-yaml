
class _EOLScanner
  fun ref scan(startMark: YamlMark val, errorContext: String, nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    /* Check if we are at the end of the line. */
    if not state.isBreakEOF() then
      return ScanError(errorContext, startMark, "did not find expected comment or line break")
    end
    this._eatLineBreak(nextScanner, state)

  fun ref _eatLineBreak(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    /* Eat a line break. */
    if state.isBreakCR() then
      this._eatLineBreakCR(nextScanner, state)
    elseif (state.isBreakLF() or state.isBreakNotCRLF()) then
      state.skipLine(1)
    end
    nextScanner.apply(state)

  fun ref _eatLineBreakCR(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this~_eatLineBreakCR(nextScanner))
    end
    if state.isBreakLF(1) then
      state.skipLine(2)
    else
      // already checked that there is a line break, cf the scan function
      state.skipLine(1)
    end
    nextScanner.apply(state)
