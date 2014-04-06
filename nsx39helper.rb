# coding: utf-8

require File.join(File.dirname(__FILE__), "nsx-39ml.rb")


# NSX-39MLをプログラムから楽に使う
class NSX39Helper
  # コンストラクタ
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


  # conductorトラック
  def conductor(&block)
    @conductors.instance_eval(&block)
  end


  # 楽譜トラック
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


  # NSX-39MLを出力する
  def to_hash
    result = { "conductor" => @conductors }
    
    @channels.each { |k, v|
      result[("channel" + k.to_s).to_s] = v
    }

    result
  end


  # MIDIファイルに保存する
  def save_to_file(filename)
    File.open(filename, "wb") { |file|
      a = create_sequence(to_hash)
      a.write(file)
    }
  end
end
