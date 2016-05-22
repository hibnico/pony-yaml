use "ponytest"
use "debug"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestToken)

class iso _TestToken is UnitTest
  fun name():String => "token"

  fun apply(h: TestHelper) =>
    h.assert_true(true)
