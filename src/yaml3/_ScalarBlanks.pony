
class _ScalarBlanks
  var leadingBreak: (None | String trn) = recover String.create() end
  var trailingBreaks: (None | String trn) = recover String.create() end
  var whitespaces: (None | String trn) = recover String.create() end
  var leadingBlank: Bool = false
  var trailingBlank: Bool = false
