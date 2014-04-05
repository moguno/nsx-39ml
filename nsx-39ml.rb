#! /usr/bin/ruby2.1

require "midilib/sequence"
require "midilib/consts"
require "yaml"

include MIDI

# バグ修正
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


def parse_key(str)
  key_map = { "C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11 }

  key = 0

  if str == "R"
    -1
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


def parse_length(str)
  1920 / str.to_i
end


def get_lyric_exclusive(code)
  [0x43, 0x79, 0x09, 0x11, 0x0a, 0x00, code]
end


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


def parse_note(channel, note)
puts note
  events = []
 
  if note["lyric"]
    events << SystemExclusive.new(get_lyric_exclusive(parse_lyric(note["lyric"])))
  end

  key = parse_key(note["key"])

  if key != -1
    events << NoteOn.new(channel, parse_key(note["key"]), 127, 0)
  end

  events << NoteOn.new(channel, parse_key(note["key"]), 0, parse_length(note["length"]))

  events
end


ml = YAML.load(File.open(ARGV[0], "rt"))








seq = Sequence.new()

track = Track.new(seq)
seq.tracks << track
track.events << Tempo.new(Tempo.bpm_to_mpq(120))

track1 = Track.new(seq)
seq.tracks << track1

ml["miku"].each { |event|
  track1.events.concat(parse_note(0, event))
}

puts "----"
puts track1.events

File.open("test.mid", "wb") { |file| seq.write(file) }