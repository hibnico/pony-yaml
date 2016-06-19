
/* Eat the rest of the line including any comments. */
class _LineTrailScanner

  fun ref scan(startMark: YamlMark val, errorContext: String, nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this~scan(startMark, errorContext, nextScanner))
    end

    while state.isBlank() do
      state.skip()
      if not state.available() then
        return ScanPaused(this~scan(startMark, errorContext, nextScanner))
      end
    end
    let s: _EOLScanner = _EOLScanner.create()
    _CommentScanner.scan(s~scan(startMark, errorContext, nextScanner), state)
