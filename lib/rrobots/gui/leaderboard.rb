# :stopdoc:
class Leaderboard
  def initialize(window, robots)
    @font_size = RRobotsGameWindow::FONT_SIZE
    @robots    = robots
    @font      = Gosu::Font.new(window, RRobotsGameWindow::BIG_FONT, @font_size)
    @x_offset  = @font_size
    @y_offset  = @font_size * 2
  end

  def draw
    if @robots # FIX: this should be populated when handed to us
      @max_size ||= @robots.keys.map { |r| r.name.length }.max

      @robots.sort_by { |(r,_)| -r.energy }.each_with_index do |(runner, ai), i|
        x = @x_offset
        y = @y_offset + i * @font_size
        c = ai.font_color

        text = "%-#{@max_size}s   %3d" % [runner.name, runner.energy]

        @font.draw(text, x, y, ZOrder::UI, 1.0, 1.0, c)
      end
    end
  end
end
