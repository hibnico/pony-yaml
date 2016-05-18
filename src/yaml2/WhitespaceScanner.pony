
primitive _WhitespaceScanner is _Scanner

  fun scan(state: _ScannerState): ScanResult
    /* Eat whitespaces. */
    if not state.buffer.available() then
      return ScanContinue
    end
    while state.buffer.isBlank() do
      state.skip()
      if not state.buffer.available() then
        return ScanContinue
      end
    end
    state.scannerStack.pop()
    ScanDone
