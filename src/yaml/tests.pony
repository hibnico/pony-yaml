use "ponytest"
use "debug"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)
  fun tag tests(test: PonyTest) =>
    test(_TestSimple)

actor _TokenCheckerCollector is YamlTokenEmitter
  let _expectedTokens: Array[YamlToken] val
  let _h: TestHelper
  var pos: USize = 0
  new create(h: TestHelper, expectedTokens: Array[YamlToken] val) =>
    _h = h
    _expectedTokens = expectedTokens
  be emit(token: YamlToken) =>
    try
      _h.assert_eq[YamlToken](token, _expectedTokens(pos))
    end
    pos = pos + 1
    if pos == _expectedTokens.size() then
      _h.complete(true)
    end

class iso _TestSimple is UnitTest
  fun name(): String => "simple"
  fun apply(h: TestHelper) =>
    h.long_test(1000000)
    let expectedTokens: Array[YamlToken] val = recover val
      let tokens: Array[YamlToken] = Array[YamlToken].create()
      tokens.push(YamlStreamStartToken.create(YamlMark.newval(0, 0, 0), YamlMark.newval(0, 0, 0), UTF8))
      tokens.push(YamlDocumentStartToken.create(YamlMark.newval(0, 0, 0), YamlMark.newval(3, 0, 3)))
      tokens.push(YamlStreamEndToken.create(YamlMark.newval(4, 1, 0), YamlMark.newval(4, 1, 0)))
      tokens
    end
    let collector = _TokenCheckerCollector.create(h, expectedTokens)
    let parser: YamlParser = YamlParser.create(collector)
    parser.read("---\n".array())
    parser.read(recover val Array[U8].create() end)
