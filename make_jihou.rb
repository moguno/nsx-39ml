# coding: utf-8

require File.join(File.dirname(__FILE__), "nsx-39ml.rb")

class NSX39Helper
  def initialize
    @conductors = []
    @channels = {}

    @conductors.instance_eval {
      def method_missing(name, *args)
        result = { "t" => name.to_s }.merge(args[0])
        self << result
        result
      end
    }
  end

  def conductor(&block)
    @conductors.instance_eval(&block)
  end

  def channel(ch, &block)
    @channels[ch] ||= []

    @channels[ch].instance_eval {
      def method_missing(name, *args)
        result = { "t" => name.to_s }.merge(args[0])
        self << result
        result
      end
    }

    @channels[ch].instance_eval(&block)
  end

  def to_hash
    result = { "conductor" => @conductors }
    
    @channels.each { |k, v|
      result[("channel" + k.to_s).to_s] = v
    }

    result
  end
end


nsx39 = NSX39Helper.new

nsx39.conductor {
  tempo("bpm" => 90)
}


def make_notes(lyrics)
  lyrics.map { |lyric|
    key = ["C", "E", "G"].sample + ["4"]. sample

    if lyric == "っ"
      {"key" => "R", "lyric" => lyric, "length" => 4}
    else
      {"key" => key, "lyric" => lyric, "length" => 4}
    end
  }
end


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

MINUTES_10_JUST = [
  [],
  [ "じゅ", "っ" ],
  [ "に", "じゅ", "っ" ],
  [ "さ", "ん", "じゅ", "っ" ],
  [ "よ", "ん", "じゅ", "っ" ],
  [ "ご", "じゅ", "っ" ],
]

MINUTES_10_FRAC = [
  [],
  [ "じゅ", "う" ],
  [ "に", "じゅ", "う" ],
  [ "さ", "ん", "じゅ", "う" ],
  [ "よ", "ん", "じゅ", "う" ],
  [ "ご", "じゅ", "う" ],
]

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


now = Time.now

lyrics = []

lyrics += HOURS[now.hour % 12] + [ "じ" ]

if now.min == 0
  # nop
elsif (now.min % 10) == 0
  lyrics += MINUTES_10_JUST[now.min / 10] + [ "ぷ", "ん" ]
else
  lyrics += MINUTES_10_FRAC[now.min / 10] + MINUTES_1[now.min % 10] + [ "ふ", "ん" ]
end

lyrics += [ "で", "す" ]

nsx39.channel(1) {
  make_notes(lyrics).each { |_note| note(_note) }
}

File.open(ARGV[0], "wb") { |file|
  a = create_sequence(nsx39.to_hash)
  a.write(file)
}
