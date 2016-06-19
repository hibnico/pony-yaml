

class _SkipLineScanner

  fun ref scan(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this~scan(nextScanner))
    end
    while not state.isBreakZ() do
      state.skip()
      if not state.available() then
        return ScanPaused(this~scan(nextScanner))
      end
    end
    nextScanner.apply(state)
