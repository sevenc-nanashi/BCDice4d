# frozen_string_literal: true

require "discorb"
require "dotenv/load"
require "bcdice"
require "bcdice/game_system"

DICES = ObjectSpace.each_object(Class).select { |klass| klass < BCDice::Base }

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.slash "roll", "ダイスを振ります。", {
  "system" => {
    description: "ゲームシステム。",
    type: :string,
    autocomplete: proc { |interaction, game_system|
      fuzzy_pattern = Regexp.new(game_system.split("").map { |c| Regexp.escape(c) }.join(".*"))
      DICES
        .filter_map { |dice| (dice::NAME.match(fuzzy_pattern) || dice::ID.match(fuzzy_pattern)) && [dice, dice::ID.match(fuzzy_pattern) || dice::NAME.match(fuzzy_pattern)] }
        .sort_by { |dice, match| match.length }
        .map { |dice, match|
        ["#{dice::NAME}(#{dice::ID})", dice::ID]
      }[..24]
    },
  },
  "expression" => {
    description: "ダイスの式。",
    type: :string,
  },
} do |interaction, game_system, expression|
  dice = BCDice.game_system_class(game_system)
  # @type [BCDice::Result]
  result = dice.eval(expression)
  unless result
    interaction.post embed: Discorb::Embed.new(
      ":question: エラー",
      "ダイスの式が正しくありません。",
      color: Discorb::Color[:red],
    )
  end
  label = "結果"
  emoji = ":information_source:"
  if result.success?
    label = "成功"
    emoji = ":white_check_mark:"
    color = Discorb::Color[:green]
  elsif result.failure?
    label = "失敗"
    emoji = ":heavy_multiplication_x:"
    color = Discorb::Color[:red]
  end
  if result.critical?
    emoji = ":star:"
    label += "（クリティカル）"
  end
  if result.fumble?
    emoji = ":boom:"
    label += "（ファンブル）"
  end
  interaction.post embed: Discorb::Embed.new(
    "#{emoji} #{label}",
    result.text,
    color: color,
  )
end

client.run ENV["TOKEN"]
