
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
  let _nextScanner: _Scanner
  var name: (None | String iso) = recover String.create() end

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if state.available() then
      return ScanPaused(this)
    end

    while state.isAlpha() do
      match state.read((name = None) as String iso^)
      | let s: String iso => name = consume s
      | let e: ScanError => return e
      end
      if not state.available() then
        return ScanPaused(this)
      end
    end

    /* Check if the name is empty. */
    if (name as String iso).size() == 0 then
      return ScanError("while scanning a directive", _startMark, "could not find expected directive name")
    end

    /* Check for an blank character after the name. */
    if not state.isBlankEOF() then
      return ScanError("while scanning a directive", _startMark, "found unexpected non-alphabetical character")
    end
    _nextScanner.apply(state)
