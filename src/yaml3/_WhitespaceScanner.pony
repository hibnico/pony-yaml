
primitive _WhitespaceScanner
  fun scan(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    /* Eat whitespaces. */
    if not state.available() then
      return ScanPaused(this~scan(nextScanner))
    end
    while state.isBlank() do
      state.skip()
      if not state.available() then
        return ScanPaused(this~scan(nextScanner))
      end
    end
    nextScanner.apply(state)
