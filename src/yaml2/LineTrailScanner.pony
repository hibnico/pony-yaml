
/* Eat the rest of the line including any comments. */
class _LineTrailScanner is _Scanner
  let _startMark: YamlMark val

  new create(mark: YamlMark) =>
    _startMark = mark

  fun scan(state: _ScannerState): ScanResult
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
    state.scannerStack.push(EOLScanner.create(_startMark))
    state.scannerStack.push(CommentScanner)
    ScanDone
