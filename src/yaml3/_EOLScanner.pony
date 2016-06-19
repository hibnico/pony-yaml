
class _EOLScanner
  fun ref scan(startMark: YamlMark val, errorContext: String, nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    /* Check if we are at the end of the line. */
    if not state.isBreakZ() then
      return ScanError(errorContext, startMark, "did not find expected comment or line break")
    end

    /* Eat a line break. */
    if state.isBreak() then
      if not state.available(2) then
        return ScanPaused(this~scan(startMark, errorContext, nextScanner))
      end
      state.skipLine()
    end
    nextScanner.apply(state)
