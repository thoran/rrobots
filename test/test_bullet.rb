require "minitest/autorun"
require "rrobots/bullet"
require "rrobots/battlefield"
require "rrobots/robot_runner"

class TestBullet < Minitest::Test
  attr_accessor :b, :bf

  def setup
    self.bf = Battlefield.new 1000, 1000, 1000, 0
    bot = :bot

    self.b = Bullet.new bf, 0, 0, 0, 100, 10, bot
  end

  def test_tick
    b.tick

    assert_equal 100, b.x
    assert_equal   0, b.y
    assert_equal   0, b.heading
    assert_equal  10, b.energy
    refute_operator b, :dead?
  end

  def test_tick_dead_boundaries
    10.times do
      b.tick
    end

    assert_equal 1000, b.x
    assert_equal    0, b.y
    assert_equal    0, b.heading
    assert_equal   10, b.energy
    assert_operator b, :dead?
  end

  def test_tick_dead_hit
    bot = RobotRunner.new nil, bf
    bot.x = 0
    bot.y = 0

    bf << bot

    enemy = RobotRunner.new nil, bf
    enemy.x = 200
    enemy.y = 0

    bf << enemy

    b.origin = bot

    b.tick

    assert_equal  100, b.x
    assert_equal    0, b.y
    refute_operator b, :dead?

    b.tick

    assert_equal  200, b.x
    assert_equal    0, b.y
    assert_operator b, :dead?
  end
end
