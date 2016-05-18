

class _EOLScanner is _Scanner
  let _startMark: YamlMark val

  new create(mark: YamlMark val) =>
    _startMark = mark

  fun scan(state: _ScannerState): ScanResult
    /* Check if we are at the end of the line. */
    if not state.buffer.isBreakZ() then
      return ScanError("while scanning a directive", _startMark, "did not find expected comment or line break")
    end

    /* Eat a line break. */
    if state.buffer.isBreak() then
      if not state.buffer.available(2)
        return ScanContinue
      end
      state.skipLine()
    end
    state.scannerStack.pop()
    ScanDone
