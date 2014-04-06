#! /usr/bin/env ruby
# coding: utf-8

require "open3"
require File.join(File.dirname(__FILE__), "nsx39helper.rb")


# 時
HOURS = [
  [ "じゅ", "う", "に" ],
  [ "い", "ち" ],
  [ "に" ],
  [ "さ", "ん" ],
  [ "よ" ],
  [ "ご" ],
  [ "ろ", "く" ],
  [ "し", "ち" ],
  [ "は", "ち" ],
  [ "く" ],
  [ "じゅ", "う" ],
  [ "じゅ", "う", "い", "ち" ]
]


# 分（10の位。10で割り切れる）
MINUTES_10_JUST = [
  [],
  [ "じゅ", "っ" ],
  [ "に", "じゅ", "っ" ],
  [ "さ", "ん", "じゅ", "っ" ],
  [ "よ", "ん", "じゅ", "っ" ],
  [ "ご", "じゅ", "っ" ],
]


# 分（10の位。10で割り切れない）
MINUTES_10_FRAC = [
  [],
  [ "じゅ", "う" ],
  [ "に", "じゅ", "う" ],
  [ "さ", "ん", "じゅ", "う" ],
  [ "よ", "ん", "じゅ", "う" ],
  [ "ご", "じゅ", "う" ],
]


# 分（1の位）
MINUTES_1 = [
  [],
  [ "い", "っ" ],
  [ "に" ],
  [ "さ", "ん" ],
  [ "よ" ,"ん" ],
  [ "ご" ],
  [ "ろ", "っ" ],
  [ "な", "な" ],
  [ "は", "ち" ],
  [ "きゅ", "う" ],
]


class NSX39Helper
  # 言葉に適当に音程を付ける
  def self.make_notes(lyrics)
    lyrics.map { |lyric|
      key = [ "C3", "E3", "G3", "C4" ].sample

      if lyric == "っ"
        {"key" => "R", "lyric" => lyric, "length" => 4}
      else
        {"key" => key, "lyric" => lyric, "length" => 4}
      end
    }
  end


  # ミクに時刻を教えてもらう
  def tell_clock!(now = Time.now)
    lyrics = []

    lyrics += HOURS[now.hour % 12] + [ "じ", "っ" ]

    if now.min == 0
      # nop
    elsif (now.min % 10) == 0
      lyrics += MINUTES_10_JUST[now.min / 10] + [ "ぷ", "ん", "っ" ]
    else
      lyrics += MINUTES_10_FRAC[now.min / 10] + MINUTES_1[now.min % 10] + [ "ふ", "ん", "っ" ]
    end

    lyrics += [ "で", "す" ]

    channel(1) {
      NSX39Helper.make_notes(lyrics).each { |_note| note(_note) }
    }
  end
end


if __FILE__ == $0
  # ALSAのNSX-39ポートを得る
  port = nil

  Open3.popen3("aplaymidi -l") { |stdin, stdout, stderr|
    stdout.each { |line|
      if line =~ /(?<port>[0-9]+:[0-9]).+NSX-39/
        port = $~[:port]
      end
    }
  }

  if !port
    STDERR.puts "NSX-39がいないよ"
    return 1
  end


  # 時報を作る
  nsx39 = NSX39Helper.new

  nsx39.conductor {
    tempo("bpm" => 150)
  }

  nsx39.tell_clock!

  nsx39.save_to_file("miku_clock.mid")


  # ALSAで再生
  system("aplaymidi miku_clock.mid -p #{port}")
end
