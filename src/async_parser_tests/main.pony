use "ponytest"
use "debug"
use "async_parser"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestToken)
    test(_TestTokenFailure)
    test(_TestAnd)
    test(_TestAndMany)
    test(_TestAndFailure)
    test(_TestOr)
    test(_TestOrMany)
    test(_TestOrFailure)
    test(_TestMany)
    test(_TestAtLeastOne)

primitive TestTokenType1 is TokenType
primitive TestTokenType2 is TokenType
primitive TestTokenType3 is TokenType
primitive TestTokenType4 is TokenType
primitive TestTokenType5 is TokenType
primitive TestTokenType6 is TokenType

class TestToken is Token
  let tokenType: TokenType

  new val create(tokenType': TokenType) =>
    tokenType = tokenType'

  fun getType(): TokenType => tokenType
