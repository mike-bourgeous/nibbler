require "helper"

class Nibbler::ParserTest < Minitest::Test

  def test_lookahead
    parser = Nibbler::Parser.new
    num = 6
    parser.instance_variable_set("@buffer", ["9", "0", "4", "0", "5", "0"])
    current = parser.send(:get_current, 0)
    output = parser.send(:lookahead, num, current) { |nibble_2, bytes| [nibble_2, bytes] }
    assert_equal([0,[0x90, 0x40, 0x50]], output[:message])
    assert_equal(["9", "0", "4", "0", "5", "0"], output[:processed])
  end

  def test_lookahead_trailing
    parser = Nibbler::Parser.new
    num = 6
    parser.instance_variable_set("@buffer", ["9", "0", "4", "0", "5", "0", "5", "0"])
    current = parser.send(:get_current, 0)
    output = parser.send(:lookahead, num, current) { |nibble_2, bytes| [nibble_2, bytes] }
    assert_equal([0,[0x90, 0x40, 0x50]], output[:message])
    assert_equal(["9", "0", "4", "0", "5", "0"], output[:processed])
  end

  def test_lookahead_too_short
    parser = Nibbler::Parser.new
    num = 6
    parser.instance_variable_set("@buffer", ["9", "0", "4"])
    current = parser.send(:get_current, 0)
    output = parser.send(:lookahead, num, current) do |nibble_2, bytes|
      {
        :message => nibble_2,
        :processed => bytes
      }
    end

    assert_nil output
  end

  def test_lookahead_sysex
    parser = Nibbler::Parser.new
    parser.instance_variable_set("@buffer", "F04110421240007F0041F750".split(//))
    current = parser.send(:get_current, 0)
    output = parser.send(:lookahead_sysex, current) { |b| b }
    assert_equal([0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7], output[:message])
    assert_equal("F04110421240007F0041F7".split(//), output[:processed])
  end

  def test_lookahead_sysex_too_short
    parser = Nibbler::Parser.new
    parser.instance_variable_set("@buffer", ["9", "0", "4"])
    current = parser.send(:get_current, 0)
    output = parser.send(:lookahead_sysex, current) { |b| b }

    assert_nil output
  end

  def test_process
    parser = Nibbler::Parser.new
    short = ["9", "0", "4", "0", "5", "0", "5", "0"]
    output = parser.send(:process, short)

    assert_equal(::MIDIMessage::NoteOn, output[:messages].first.class)
    assert_equal(["5", "0"], parser.buffer)
    assert_equal(["9", "0", "4", "0", "5", "0"], output[:processed])
  end

  def test_process_running_status
    parser = Nibbler::Parser.new
    two_msgs = ["9", "0", "4", "0", "5", "0", "4", "0", "6", "0"]
    output = parser.send(:process, two_msgs)

    refute_nil output
    assert_equal(::MIDIMessage::NoteOn, output[:messages][0].class)
    assert_equal(::MIDIMessage::NoteOn, output[:messages][1].class)
    assert_empty(parser.buffer)
    assert_equal(["9", "0", "4", "0", "5", "0", "4", "0", "6", "0"], output[:processed])
  end

  def test_process_multiple_overlapping_calls
    parser = Nibbler::Parser.new
    short = ["9", "0", "4", "0", "5", "0", "9", "0"]
    short2 = ["3", "0", "2", "0", "1", "0"]

    output = parser.send(:process, short)

    refute_nil output
    assert_equal(::MIDIMessage::NoteOn, output[:messages].first.class)
    assert_equal(["9", "0"], parser.buffer)
    assert_equal(["9", "0", "4", "0", "5", "0"], output[:processed])

    output2 = parser.send(:process, short2)

    refute_nil output2
    assert_equal(::MIDIMessage::NoteOn, output2[:messages].first.class)
    assert_equal(["1", "0"], parser.buffer)
    assert_equal(["9", "0", "3", "0", "2", "0"], output2[:processed])
  end

  def test_nibbles_to_message_leading
    parser = Nibbler::Parser.new
    short = ["5", "0", "9", "0", "4", "0", "5", "0"]
    parser.instance_variable_set("@buffer", short)
    current = parser.send(:get_current, 0)
    output = parser.send(:nibbles_to_message, current)

    assert_nil output
    assert_equal(["5", "0", "9", "0", "4", "0", "5", "0"], parser.buffer)
  end

  def test_nibbles_to_message_trailing
    parser = Nibbler::Parser.new
    short = ["9", "0", "4", "0", "5", "0", "5", "0"]
    parser.instance_variable_set("@buffer", short)
    current = parser.send(:get_current, 0)
    output = parser.send(:nibbles_to_message, current)

    refute_nil output
    assert_equal(::MIDIMessage::NoteOn, output[:message].class)
    assert_equal(["9", "0", "4", "0", "5", "0"], output[:processed])
  end

  def test_nibbles_to_message
    parser = Nibbler::Parser.new
    short = ["9", "0", "4", "0", "5", "0", "5", "0"]
    parser.instance_variable_set("@buffer", short)
    current = parser.send(:get_current, 0)
    output = parser.send(:nibbles_to_message, current)

    refute_nil output
    assert_equal(::MIDIMessage::NoteOn, output[:message].class)
    assert_equal(["9", "0", "4", "0", "5", "0"], output[:processed])
  end

  def test_nibbles_to_message_running_status
    parser = Nibbler::Parser.new
    short = ["9", "0", "4", "0", "5", "0"]
    parser.instance_variable_set("@buffer", short)
    current = parser.send(:get_current, 0)
    output = parser.send(:nibbles_to_message, current)

    refute_nil output
    assert_equal(::MIDIMessage::NoteOn, output[:message].class)

    running_status = ["5", "0", "6", "0"]
    parser.instance_variable_set("@buffer", running_status)
    current = parser.send(:get_current, 0)
    output = parser.send(:nibbles_to_message, current)

    refute_nil output
    assert_equal(::MIDIMessage::NoteOn, output[:message].class)
    assert_equal(["5", "0", "6", "0"], output[:processed])
  end

  def test_nibbles_to_message_sysex
    parser = Nibbler::Parser.new
    sysex = "F04110421240007F0041F750".split(//)
    parser.instance_variable_set("@buffer", sysex)
    current = parser.send(:get_current, 0)
    output = parser.send(:nibbles_to_message, current)

    refute_nil output
    assert_equal(::MIDIMessage::SystemExclusive::Command, output[:message].class)
    assert_equal("F04110421240007F0041F7".split(//), output[:processed])
  end

  def test_message_library
    parser = Nibbler::Parser.new(:message_lib => :midilib)
    assert_equal Nibbler::Midilib, parser.instance_variable_get("@message")

    parser = Nibbler::Parser.new
    assert_equal Nibbler::MIDIMessage, parser.instance_variable_get("@message")
  end

end
