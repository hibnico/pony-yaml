

primitive _SkipLineScanner is _Scanner

  fun scan(state: _ScannerState): ScanResult
    if not state.buffer.available() then
      return ScanContinue
    end
    while not state.buffer.isBreakZ() do
      state.skip()
      if not state.buffer.available() then
        return ScanContinue
      end
    end
    state.scannerStack.pop()
    ScanDone
