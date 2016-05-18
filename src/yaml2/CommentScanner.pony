
primitive _CommentScanner is _Scanner

  fun scan(state: _ScannerState): ScanResult
    if not state.buffer.available() then
      ScanContinue
    end
    state.scannerStack.pop()
    if state.buffer.check('#') then
      state.scannerStack.push(_SkipLineScanner)
    end
    ScanDone
