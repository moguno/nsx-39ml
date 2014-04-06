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

nsx39.channel(1) {
  ["じゅ", "う", "じ"].each { |lyric|
    key = ["C", "E", "G"].sample + ["4", "5"]. sample

    note("key" => key, "lyric" => lyric, "length" => 4)
  }

  ["さ", "ん２", "じゅ", "う"].each { |lyric|
    key = ["C", "E", "G"].sample + ["4"]. sample

    note("key" => key, "lyric" => lyric, "length" => 4)
  }

  ["に"].each { |lyric|
    key = ["C", "E", "G"].sample + ["4"]. sample

    note("key" => key, "lyric" => lyric, "length" => 4)
  }

  ["ふ", "ん２"].each { |lyric|
    key = ["C", "E", "G"].sample + ["4"]. sample

    note("key" => key, "lyric" => lyric, "length" => 4)
  }
}

File.open(ARGV[0], "wb") { |file|
  a = create_sequence(nsx39.to_hash)
  a.write(file)
}
