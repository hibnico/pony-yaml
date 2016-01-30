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
