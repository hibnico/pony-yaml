
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
    if (nameScanner.name as String trn) == "YAML" then
      let s = _VersionDirectiveValueScanner(_startMark, this~_scanVersion())
      _versionScanner = s
      s.apply(state)
    /* Is it a TAG directive? */
    elseif (nameScanner.name as String trn) == "TAG" then
      let s = _TagDirectiveValueScanner(_startMark, this~_scanTagValue())
      _tagScanner = s
      s.apply(state)
    /* Unknown directive. */
    else
      ScanError("while scanning a directive", _startMark, "found unknown directive name")
    end

  fun ref _scanVersion(state: _ScannerState): _ScanResult ? =>
    let versionScanner = _versionScanner as _VersionDirectiveValueScanner
    state.emitToken(_YamlVersionDirectiveToken(_startMark, state.mark.clone(), _YamlVersionDirectiveTokenData(versionScanner.major, versionScanner.minor)))
    _LineTrailScanner.scan(_startMark, "while scanning a directive", _nextScanner, state)

  fun ref _scanTagValue(state: _ScannerState): _ScanResult ? =>
    let tagScanner = _tagScanner as _TagDirectiveValueScanner
    state.emitToken(_YamlTagDirectiveToken(_startMark, state.mark.clone(), _YamlTagDirectiveTokenData.create((tagScanner.handle as String).clone(), (tagScanner.prefix as String).clone())))
    _LineTrailScanner.scan(_startMark, "while scanning a directive", _nextScanner, state)

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
  var name: (None | String trn) = recover String.create() end

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if state.available() then
      return ScanPaused(this)
    end

    while state.isAlpha() do
      match state.read((name = None) as String trn^)
      | let s: String trn => name = consume s
      | let e: ScanError => return e
      end
      if not state.available() then
        return ScanPaused(this)
      end
    end

    /* Check if the name is empty. */
    if (name as String trn).size() == 0 then
      return ScanError("while scanning a directive", _startMark, "could not find expected directive name")
    end

    /* Check for an blank character after the name. */
    if not state.isBlankZ() then
      return ScanError("while scanning a directive", _startMark, "found unexpected non-alphabetical character")
    end
    _nextScanner.apply(state)

/*
 * Scan a YAML-DIRECTIVE or TAG-DIRECTIVE token.
 *
 * Scope:
 *      %YAML    1.1    # a commentn
 *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 *      %TAG    !yaml!  tag:yaml.org,2002:n
 *      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */
class _TagDirectiveValueScanner is _Scanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _tagHandleScanner: (None | _TagHandleScanner) = None
  var _tagURIScanner: (None | _TagURIScanner) = None
  var handle: (None | String val) = None
  var prefix: (None | String val) = None

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    let s = _TagHandleScanner.create(true, _startMark, this~_scanWhitespace())
    _tagHandleScanner = s
    s.apply(state)

  fun ref _scanWhitespace(state: _ScannerState): _ScanResult ? =>
    /* Expect a whitespace. */
    if not state.available() then
      return ScanPaused(this~_scanWhitespace())
    end
    if not state.isBlank() then
      return ScanError("while scanning a %TAG directive", _startMark, "did not find expected whitespace")
    end
    let s = _TagURIScanner.create(true, None, _startMark, this~_scanWhitespaceOrLineBreak())
    _tagURIScanner = s
    s.apply(state)

  fun ref _scanWhitespaceOrLineBreak(state: _ScannerState): _ScanResult ? =>
    /* Expect a whitespace or line break. */
    if not state.available() then
      return ScanPaused(this~_scanWhitespaceOrLineBreak())
    end
    if not state.isBlankZ() then
      return ScanError("while scanning a %TAG directive", _startMark, "did not find expected whitespace or line break")
    end
    let tagHandleScanner = _tagHandleScanner as _TagHandleScanner
    handle = (tagHandleScanner.handle = None) as String^
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    prefix = (tagURIScanner.uri = None) as String^
    _nextScanner.apply(state)


/*
 * Scan the version number of VERSION-DIRECTIVE.
 *
 * Scope:
 *      %YAML   1.1     # a commentn
 *              ^
 *      %YAML   1.1     # a commentn
 *                ^
 */
class _VersionDirectiveNumberScanner is _Scanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var value: U16 = 0
  var length: USize = 0

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Repeat while the next character is digit. */
    if not state.available() then
      return ScanPaused(this)
    end
    while state.isDigit() do
      /* Check if the number is too long. */
      length = length + 1
      if length > MAX_NUMBER_LENGTH then
        return ScanError("while scanning a %YAML directive", _startMark, "found extremely long version number")
      end
      value = (value * 10) + state.asDigit().u16()
      state.skip()
      if not state.available() then
        return ScanPaused(this)
      end
    end
    /* Check if the number was present. */
    if length == 0 then
      return ScanError("while scanning a %YAML directive", _startMark, "did not find expected version number")
    end
    _nextScanner.apply(state)

/*
 * Scan the value of VERSION-DIRECTIVE.
 *
 * Scope:
 *      %YAML   1.1     # a commentn
 *           ^^^^^^
 */
class _VersionDirectiveValueScanner is _Scanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _versionScanner: (None | _VersionDirectiveNumberScanner) = None
  var major: U16 = 0
  var minor: U16 = 0

  new create(mark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    let s = _VersionDirectiveNumberScanner.create(_startMark, _WhitespaceScanner~scan(this~_scanDot()))
    _versionScanner = s
    s.apply(state)

  fun ref _scanDot(state: _ScannerState): _ScanResult ? =>
    let versionScanner = _versionScanner as _VersionDirectiveNumberScanner
    major = versionScanner.value
    /* Eat '.'. */
    if not state.check('.') then
      return ScanError("while scanning a %YAML directive", _startMark, "did not find expected digit or '.' character")
    end
    state.skip()
    let s = _VersionDirectiveNumberScanner.create(_startMark, this~_scanEnd())
    _versionScanner = s
    s.apply(state)

  fun ref _scanEnd(state: _ScannerState): _ScanResult ? =>
    let versionScanner = _versionScanner as _VersionDirectiveNumberScanner
    minor = versionScanner.value
    _nextScanner.apply(state)


primitive _WhitespaceScanner
  fun scan(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    /* Eat whitespaces. */
    if not state.available() then
      return ScanPaused(this~scan(nextScanner))
    end
    while state.isBlank() do
      state.skip()
      if not state.available() then
        return ScanPaused(this~scan(nextScanner))
      end
    end
    nextScanner.apply(state)
