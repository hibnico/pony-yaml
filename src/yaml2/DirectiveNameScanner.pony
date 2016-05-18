
/*
 * Scan the directive name.
 *
 * Scope:
 *      %YAML   1.1     # a commentn
 *       ^^^^
 *      %TAG    !yaml!  tag:yaml.org,2002:n
 *       ^^^
 */
class _DirectiveNameScanner is _Scanner
  let _startMark: YamlMark val
  let name: String = String()

  new create(mark: YamlMark val) =>
    _startMark = mark

  fun scan(state: _ScannerState): ScanResult =>
    if state.buffer.available() then
      return ScanContinue
    end

    while state.buffer.isAlpha() do
      let res = state.buffer.read(name)
      if res is ScanError then
        return try res as ScanError end
      end
      if not state.buffer.available() then
        return ScanContinue
      end
    end

    /* Check if the name is empty. */
    if name.size() == 0 then
      return ScanError("while scanning a directive", _startMark, "could not find expected directive name")
    end

    /* Check for an blank character after the name. */
    if not state.buffer.isBlankZ() then
      return ScanError("while scanning a directive", _startMark, "found unexpected non-alphabetical character")
    end
    state.scannerStack.pop()
    ScanDone
