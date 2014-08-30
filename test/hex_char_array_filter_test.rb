require "helper"

class Nibbler::HexCharArrayFilterTest < Test::Unit::TestCase
  
  def test_to_nibbles_array_mixed
    filter = Nibbler::HexCharArrayFilter.new
    array = [0x90, "90", "9"]
    nibbles = filter.send(:process, array)
    assert_equal([0x90, "90", "9"], array)
    assert_equal(["9", "0", "9", "0", "9"], nibbles)     
  end
  
  def test_to_nibbles_mixed
    filter = Nibbler::HexCharArrayFilter.new
    array = [0x90, "90", "9"]
    nibbles = filter.send(:process, *array)
    assert_equal([0x90, "90", "9"], array)
    assert_equal(["9", "0", "9", "0", "9"], nibbles)     
  end

  def test_to_nibbles_numeric
    filter = Nibbler::HexCharArrayFilter.new
    num = 0x90
    nibbles = filter.send(:process, num)
    assert_equal(0x90, num)
    assert_equal(["9", "0"], nibbles)     
  end                

  def test_to_nibbles_string
    filter = Nibbler::HexCharArrayFilter.new
    str = "904050"
    nibbles = filter.send(:process, str)
    assert_equal("904050", str)
    assert_equal(["9", "0", "4", "0", "5", "0"], nibbles)     
  end
    
  def test_filter_numeric
    filter = Nibbler::HexCharArrayFilter.new
    badnum = 560
    output = filter.send(:filter_numeric, badnum)
    assert_equal(560, badnum)
    assert_equal(nil, output)     
    goodnum = 50
    output = filter.send(:filter_numeric, goodnum)
    assert_equal(50, goodnum)
    assert_equal(50, output)     
  end
  
  def test_filter_string
    filter = Nibbler::HexCharArrayFilter.new
    str = "(0xAdjskla#(#"
    outp = filter.send(:filter_string, str)
    assert_equal("0ADA", outp)
  end
  
end
