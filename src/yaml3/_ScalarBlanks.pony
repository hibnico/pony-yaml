
class _ScalarBlanks
  var leadingBreak: (None | String iso) = recover String.create() end
  var trailingBreaks: (None | String iso) = recover String.create() end
  var whitespaces: (None | String iso) = recover String.create() end
  var leadingBlank: Bool = false
  var trailingBlank: Bool = false
