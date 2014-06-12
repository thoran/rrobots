require "minitest/autorun"
require "rrobots/explosion"

class TestExplosion < Minitest::Test
  def test_tick
    e = Explosion.new nil, 0, 0

    assert_equal 0, e.t
    refute_operator e, :dead?

    16.times do |n|
      e.tick
    end

    assert_equal 16, e.t
    assert_operator e, :dead?
  end
end
