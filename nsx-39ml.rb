#! /usr/bin/env ruby
# coding: utf-8

require "rubygems"
require "midilib/sequence"
require "midilib/consts"
require "yaml"

include MIDI


# midilibのバグ修正
class SystemExclusive
  def data_as_bytes
    data = []
    data << @status
    data << Utils.as_var_len(@data.length + 1)
    data << @data
    data << EOX
    data.flatten
  end
end


# conductorトラックのパース
def parse_conductor(ml)
  events = []

  # XGシステムONだと・・・？俺のNSX-39の真の力が解放されると言うのか！
  events << SystemExclusive.new([0x43, 0x10, 0x4c, 0x00, 0x00, 0x7e, 0x00])

  ml.each { |event|
    event = case event["t"]
    when "tempo"
      Tempo.new(Tempo.bpm_to_mpq(event["bpm"]))
    end

    if event
      events << event
    end
  }

  events
end


# キーのパース
def parse_key(str)
  key_map = { "C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11 }

  key = 0

  if str == "R"
    key = -1
  elsif str =~ /^(?<key>[A-GR])(?<sharp>[-\#+])?(?<octave>[0-9])$/
    key = ($~[:octave].to_i + 2) * 12 + key_map[$~[:key]]

    case $~[:sharp]
    when "-"
      key -= 1
    when "+"
      key += 1
    end
  else
    raisze "はみゃ？:" + str
  end

  key
end


# 長さ情報のパース
def parse_length(str)
  1920 / str.to_i
end


# 歌詞エクスクルーシブを生成する
def get_lyric_exclusive(code)
  [0x43, 0x79, 0x09, 0x11, 0x0a, 0x00, code]
end


# 歌詞をパース
def parse_lyric(str)
  lyric_table = {
    "あ" => 0x00,
    "い" => 0x01,
    "う" => 0x02,
    "え" => 0x03,
    "お" => 0x04,

    "か" => 0x05,
    "き" => 0x06,
    "く" => 0x07,
    "け" => 0x08,
    "こ" => 0x09,

    "が" => 0x0A,
    "ぎ" => 0x0B,
    "ぐ" => 0x0C,
    "げ" => 0x0D,
    "ご" => 0x0E,

    "きゃ" => 0x0F,
    "きゅ" => 0x10,
    "きょ" => 0x11,

    "ぎゃ" => 0x12,
    "ぎゅ" => 0x13,
    "ぎょ" => 0x14,

    "さ" => 0x15,
    "すぃ" => 0x16,
    "す" => 0x17,
    "せ" => 0x18,
    "そ" => 0x19,

    "ざ" => 0x1A,
    "ずぃ" => 0x1B,
    "ず" => 0x1C,
    "ぜ" => 0x1D,
    "ぞ" => 0x1E,

    "しゃ" => 0x1F,
    "し" => 0x20,
    "しゅ" => 0x21,
    "しぇ" => 0x22,
    "しょ" => 0x23,

    "じゃ" => 0x24,
    "じ" => 0x25,
    "じゅ" => 0x26,
    "じぇ" => 0x27,
    "じょ" => 0x28,

    "た" => 0x29,
    "てぃ" => 0x2A,
    "とぅ" => 0x2B,
    "て" => 0x2C,
    "と" => 0x2D,

    "だ" => 0x2E,
    "でぃ" => 0x2F,
    "どぅ" => 0x30,
    "で" => 0x31,
    "ど" => 0x32,

    "てゅ" => 0x33,
    "でゅ" => 0x34,

    "ちゃ" => 0x35,
    "ち" => 0x36,
    "ちゅ" => 0x37,
    "ちぇ" => 0x38,
    "ちょ" => 0x39,

    "つぁ" => 0x3A,
    "つぃ" => 0x3B,
    "つ" => 0x3C,
    "つぇ" => 0x3D,
    "つぉ" => 0x3E,

    "な" => 0x3F,
    "に" => 0x40,
    "ぬ" => 0x41,
    "ね" => 0x42,
    "の" => 0x43,

    "にゃ" => 0x44,
    "にゅ" => 0x45,
    "にょ" => 0x46,

    "は" => 0x47,
    "ひ" => 0x48,
    "ふ" => 0x49,
    "へ" => 0x4A,
    "ほ" => 0x4B,

    "ば" => 0x4C,
    "び" => 0x4D,
    "ぶ" => 0x4E,
    "べ" => 0x4F,
    "ぼ" => 0x50,

    "ぱ" => 0x51,
    "ぴ" => 0x52,
    "ぷ" => 0x53,
    "ぺ" => 0x54,
    "ぽ" => 0x55,

    "ひゃ" => 0x56,
    "ひゅ" => 0x57,
    "ひょ" => 0x58,

    "びゃ" => 0x59,
    "びゅ" => 0x5A,
    "びょ" => 0x5B,

    "ぴゃ" => 0x5C,
    "ぴゅ" => 0x5D,
    "ぴょ" => 0x5E,

    "ふぁ" => 0x5F,
    "ふぃ" => 0x60,
    "ふゅ" => 0x61,
    "ふぇ" => 0x62,
    "ふぉ" => 0x63,

    "ま" => 0x64,
    "み" => 0x65,
    "む" => 0x66,
    "め" => 0x67,
    "も" => 0x68,

    "みゃ" => 0x69,
    "みゅ" => 0x6A,
    "みょ" => 0x6B,

    "や" => 0x6C,
    "ゆ" => 0x6D,
    "よ" => 0x6E,

    "ら" => 0x6F,
    "り" => 0x70,
    "る" => 0x71,
    "れ" => 0x72,
    "ろ" => 0x73,

    "りゃ" => 0x74,
    "りゅ" => 0x75,
    "りょ" => 0x76,

    "わ" => 0x77,
    "うぃ" => 0x78,
    "うぇ" => 0x79,
    "うぉ" => 0x7A,

    "ん" => 0x7B,
    "ん２" => 0x7C,
    "ん３" => 0x7D,
    "ん４" => 0x7E,
    "ん５" => 0x7F
  }

  lyric_table[str]
end


# システムエクスクルーシブ
def parse_exclusive(channel, exclusive)
  events = []

  events << SystemExclusive.new(exclusive["data"])

  events
end


# コントロールチェンジ
def parse_control(channel, control)
  events = []

  events << Controller.new(channel, control["type"], control["value"])

  events
end


# プログラムチェンジ
def parse_program(channel, program)
  events = []

  events << ProgramChange.new(channel, program["tone_no"])
end

alias parse_tone parse_program


# ノート情報のパース
def parse_note(channel, note)
  events = []
 
  if note["key"] != "R" && note["lyric"]
    events << SystemExclusive.new(get_lyric_exclusive(parse_lyric(note["lyric"])))
  end

  if note["vibrate"]
    events << Controller.new(channel, 1, note["vibrate"].to_i)
  end

  key = parse_key(note["key"])

  if key == -1
    events << NoteOn.new(channel, 1, 0, parse_length(note["length"]))
  else
    events << NoteOn.new(channel, key, 127, 0)
    events << NoteOn.new(channel, key, 0, parse_length(note["length"]))
  end

  if note["vibrate"]
    events << Controller.new(channel, 1, 0)
  end

  events
end


# NSX-39MLのハッシュからMIDIシーケンスデータを構築する
def create_sequence(ml)
  seq = Sequence.new()

  # 設定トラック
  if ml["conductor"]
    conductor_track = Track.new(seq)
    seq.tracks << conductor_track

    events = parse_conductor(ml["conductor"])

    conductor_track.events.concat(events)
  end

  # ミクたそトラック
  if ml["miku"]
    miku_track = Track.new(seq)
    seq.tracks << miku_track

    ml["miku"].each { |event|
      events = self.send(("parse_" + event["t"].to_s ).to_sym, 0, event)

      if events
        miku_track.events.concat(events)
      end
    }
  end

  # バックバンド
  ml.select { |k, v| k =~ /^channel1?[0-9]$/ }.each { |k, v|
    band_track = Track.new(seq)
    seq.tracks << band_track

    k =~ /^channel(?<channel>.+)$/

    channel = $~[:channel].to_i - 1

    band_track.events << ProgramChange.new(channel, 20, 12)

    v.each { |event|
      events = self.send(("parse_" + event["t"].to_s ).to_sym, channel, event)

      if events
        band_track.events.concat(events)
      end
    }
  }

  seq
end


macros = {}

def load_macros(ml)
  if ml["macro"]
    ml["macro"].each { |macro|
      define_singleton_method("parse_" + macro["t"]) { |channel, event|
        events = []

        macro["macro"].each { |m|
          e = {}

          m.each { |k, v|
            # 変数
            if v =~ /^\$(?<var>.+)(:(?<cls>.+))?$/
              if $~[:cls]
              else
                if event[$~[:var]]
                  e[k] = event[$~[:var]]
                else
                  raise "みゃー"
                end 
              end
            else
              e[k] = v
            end
          }
puts e
          events += self.send(("parse_" + e["t"].to_s ).to_sym, channel, e)
puts events
        }

        events
      }
    }
  end
end


if __FILE__ == $0
  macro_ml = YAML.load(File.open("reverve.39h", "rt"))

  load_macros(macro_ml)

  ml = YAML.load(File.open(ARGV[0], "rt"))
  seq = create_sequence(ml)

  File.open(ARGV[1], "wb") { |file|
    seq.write(file)
  }
end
