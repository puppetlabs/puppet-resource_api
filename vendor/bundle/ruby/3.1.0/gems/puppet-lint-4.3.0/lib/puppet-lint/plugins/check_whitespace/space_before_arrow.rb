# frozen_string_literal: true

# Check the manifest tokens for any arrows (=>) that have too much space
# before them in situations when a given resource has at most one line with
# such arrows. For example:

# file {
#   # too much space after "foo"
#   foo⎵⎵=>⎵'bar'
# }
#
# file {
#   # too much space after 'bar'
#   foo⎵=>⎵{ bar⎵⎵=>⎵'baz' }
# }
#

# Linting multi-parameter resources like this:
#
# package { 'xxx':
#   foo => 'bar',
#   bar  => 'baz',
# }
#
# is handled by the "arrow_alignment" plugin.

PuppetLint.new_check(:space_before_arrow) do
  def check
    resource_indexes.each do |res_idx|
      resource_tokens = res_idx[:tokens]
      resource_tokens.reject! do |token|
        Set[:COMMENT, :SLASH_COMMENT, :MLCOMMENT].include?(token.type)
      end

      first_arrow = resource_tokens.index { |r| r.type == :FARROW }
      last_arrow = resource_tokens.rindex { |r| r.type == :FARROW }
      next if first_arrow.nil?
      next if last_arrow.nil?

      # If this is a single line resource, skip it
      next unless resource_tokens[first_arrow].line == resource_tokens[last_arrow].line

      resource_tokens.select { |token| token.type == :FARROW }.each do |token|
        prev_token = token.prev_token
        next unless prev_token
        next if prev_token.value == ' '

        line = prev_token.line
        column = prev_token.column

        notify(
          :warning,
          message: "there should be a single space before '=>' on line #{line}, column #{column}",
          line: line,
          column: column,
          token: prev_token,
        )
      end
    end
  end

  def fix(problem)
    token = problem[:token]

    if token.type == :WHITESPACE
      token.value = ' '
      return
    end

    add_token(tokens.index(token), PuppetLint::Lexer::Token.new(:WHITESPACE, ' ', 0, 0))
  end
end
