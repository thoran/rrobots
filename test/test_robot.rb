require "minitest/autorun"
require "rrobots/robot"
require "rrobots/robot_runner"
require "rrobots/battlefield"

class Thingy
  include Robot
end

class TestRobot < Minitest::Test
  attr_accessor :r, :rr, :bf

  def setup
    self.bf = Battlefield.new 1000, 1000, 1000, 0
    self.r  = Thingy.new
    self.rr = RobotRunner.new r, bf

    rr.update_state
  end

  def test_accelerate
    r.accelerate 1

    assert_equal 1, r.actions[:accelerate]
  end

  def test_broadcast
    r.broadcast "woot"

    assert_equal "woot", r.actions[:broadcast]
  end

  def test_broadcasts
    r.events['broadcasts'] = ["woot", "west"] # FIX: horrible

    assert_equal ["woot", "west"], r.broadcasts
  end

  def test_fire
    r.fire 3

    assert_equal 3, r.actions[:fire]
  end

  def test_got_hit
    r.events["got_hit"] = [3] # FIX: horrible

    assert_equal [3], r.got_hit
  end

  def test_robot_scanned
    r.events["robot_scanned"] << [100, 45]

    assert_equal [[100, 45]], r.robot_scanned
  end

  def test_say
    r.say "woot"

    assert_equal "woot", r.actions[:say]
  end

  def test_stop_positive
    r.speed = 3

    r.stop

    assert_equal -1, r.actions[:accelerate]
  end

  def test_stop_negative
    r.speed = -3

    r.stop

    assert_equal 1, r.actions[:accelerate]
  end

  def test_stop_stopped
    r.speed = 0

    r.stop

    assert_equal 0, r.actions[:accelerate]
  end

  def test_tick
    assert_raises NotImplementedError do
      r.tick nil
    end
  end

  def test_turn
    r.turn 90

    assert_equal 90, r.actions[:turn]
  end

  def test_turn_gun
    r.turn_gun 90

    assert_equal 90, r.actions[:turn_gun]
  end

  def test_turn_radar
    r.turn_radar 90

    assert_equal 90, r.actions[:turn_radar]
  end
end
