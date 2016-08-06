
class _CommentScanner
  fun ref scan(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      ScanPaused(this~scan(nextScanner))
    end
    if state.check('#') then
      _SkipLineScanner.create().scan(nextScanner, state)
    else
      nextScanner.apply(state)
    end
