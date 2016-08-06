
/*
 * Scan a YAML-DIRECTIVE or TAG-DIRECTIVE token.
 *
 * Scope:
 *      %YAML    1.1    # a commentn
 *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 *      %TAG    !yaml!  tag:yaml.org,2002:n
 *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */
class _DirectiveScanner is _Scanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _nameScanner: (None | _DirectiveNameScanner) = None
  var _versionScanner: (None | _VersionDirectiveValueScanner) = None
  var _tagScanner: (None | _TagDirectiveValueScanner) = None

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Eat '%'. */
    state.skip()
    let s = _DirectiveNameScanner.create(_startMark, this~_scanValue())
    _nameScanner = s
    s.apply(state)

  fun ref _scanValue(state: _ScannerState): _ScanResult ? =>
    let nameScanner = _nameScanner as _DirectiveNameScanner
    /* Is it a YAML directive? */
    if (nameScanner.name as String iso) == "YAML" then
      let s = _VersionDirectiveValueScanner(_startMark, this~_scanVersion())
      _versionScanner = s
      s.apply(state)
    /* Is it a TAG directive? */
    elseif (nameScanner.name as String iso) == "TAG" then
      let s = _TagDirectiveValueScanner(_startMark, this~_scanTagValue())
      _tagScanner = s
      s.apply(state)
    /* Unknown directive. */
    else
      ScanError("while scanning a directive", _startMark, "found unknown directive name")
    end

  fun ref _scanVersion(state: _ScannerState): _ScanResult ? =>
    let versionScanner = _versionScanner as _VersionDirectiveValueScanner
    match state.emitToken(YamlVersionDirectiveToken(_startMark, state.mark.clone(), versionScanner.major, versionScanner.minor))
    | let e: ScanError => return e
    end
    _LineTrailScanner.scan(_startMark, "while scanning a directive", _nextScanner, state)

  fun ref _scanTagValue(state: _ScannerState): _ScanResult ? =>
    let tagScanner = _tagScanner as _TagDirectiveValueScanner
    match state.emitToken(YamlTagDirectiveToken(_startMark, state.mark.clone(), (tagScanner.handle as String).clone(), (tagScanner.prefix as String).clone()))
    | let e: ScanError => return e
    end
    _LineTrailScanner.scan(_startMark, "while scanning a directive", _nextScanner, state)
