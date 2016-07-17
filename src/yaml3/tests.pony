use "ponytest"
use "debug"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  fun tag tests(test: PonyTest) =>
    test(_TestSimple)

actor _TokenCheckerCollector is TokenEmitter
  let _expectedTokens: Array[_YAMLToken] val
  let _h: TestHelper
  var pos: USize = 0
  new create(h: TestHelper, expectedTokens: Array[_YAMLToken] val) =>
    _h = h
    _expectedTokens = expectedTokens
  be emit(token: _YAMLToken) =>
    try
      _h.assert_eq[_YAMLToken](token, _expectedTokens(pos))
    end
    Debug.out(token)
    pos = pos + 1
    if pos == _expectedTokens.size() then
      _h.complete(true)
    end

class iso _TestSimple is UnitTest
  fun name(): String => "simple"
  fun apply(h: TestHelper) =>
    h.long_test(1000)
    let expectedTokens: Array[_YAMLToken] val = recover val
      let tokens: Array[_YAMLToken] = Array[_YAMLToken].create()
      tokens.push(_YamlStreamStartToken.create(YamlMark.newval(0, 0, 0), YamlMark.newval(0, 0, 0), UTF8))
      tokens.push(_YamlDocumentStartToken.create(YamlMark.newval(0, 0, 0), YamlMark.newval(3, 0, 3)))
      tokens.push(_YamlStreamEndToken.create(YamlMark.newval(3, 0, 3), YamlMark.newval(0, 0, 0)))
      tokens
    end
    let collector = _TokenCheckerCollector.create(h, expectedTokens)
    let parser: Parser = Parser.create(collector)
    parser.read("---\n".array())
    parser.read(recover val Array[U8].create() end)
