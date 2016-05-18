
primitive _ScanName
primitive _ScanValue
primitive _ScanVersion
primitive _ScanTagValue
type _State is (None | _ScanValue | _ScanVersion | _ScanTagValue)

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
  var _state: _State = None
  var _nameScanner: (None | _DirectiveNameScanner) = None
  var _versionScanner: (None | _VersionDirectiveValueScanner) = None
  var _tagScanner: (None | _TagDirectiveValueScanner) = None

  new create(mark: YamlMark val) =>
    _startMark = mark

  fun scan(state: _ScannerState): _ScanResult =>
    match _state
    | None => _startScan(state)
    | _ScanValue => _scanValue(state)
    | _ScanVersion => _scanVersion(state)
    | _ScanTagValue => _scanTagValue(state)

  fun _startScan(state: _ScannerState): ScanResult =>
    /* Eat '%'. */
    state.skip()
    _state = _ScanValue
    let s = _DirectiveNameScanner(_startMark)
    state.scannerStack.push(s)
    _nameScanner = s
    ScanContinue

  fun _scanValue(state: _ScannerState): ScanResult =>
    let nameScanner = try _nameScanner as _DirectiveNameScanner end
    /* Is it a YAML directive? */
    if nameScanner.name == "YAML" then
      _state = _ScanVersion
      let s = _VersionDirectiveValueScanner(_startMark)
      state.scannerStack.push(s)
      _versionScanner = s
      ScanContinue
    /* Is it a TAG directive? */
    elseif nameScanner.name == "TAG" then
      _state = _ScanTagValue
      let s = _TagDirectiveValueScanner(_startMark)
      state.scannerStack.push(s)
      _tagScanner = s
      ScanContinue
    /* Unknown directive. */
    else
      ScanError("while scanning a directive", _startMark, "found unknown directive name")
    end

  fun _scanVersion(state: _ScannerState): ScanResult =>
    let versionScanner = try _versionScanner as _VersionDirectiveValueScanner end
    state.emitToken(_YAMLToken(YAML_VERSION_DIRECTIVE_TOKEN, _startMark, state.mark.clone(), _YamlVersionDirectiveTokenData(versionScanner.major, versionScanner.minor)))
    state.scannerStack.replace(_LineTrailScanner.create(_startMark))
    ScanDone

  fun _scanTagValue(state: _ScannerState): ScanResult =>
    let tagScanner = try _tagScanner as _TagDirectiveValueScanner end
    state.emitToken(_YAMLToken(YAML_TAG_DIRECTIVE_TOKEN, _startMark, state.mark.clone(), tagScanner.handle, tagScanner.prefix))
    state.scannerStack.replace(_LineTrailScanner.create(_startMark))
    ScanDone
