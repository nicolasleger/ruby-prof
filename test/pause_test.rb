#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../test_helper', __FILE__)

class PauseTest < Test::Unit::TestCase
  def setup
    # Need to use wall time for this test due to the sleep calls
    RubyProf::measure_mode = RubyProf::WALL_TIME
  end

  def test_pause_resume
  #  ENV['RUBY_PROF_TRACE'] = 'c:\\temp\\trace.txt'
    RubyProf.start
    # Measured
    RubyProf::C1.hello
    RubyProf.pause

    # Not measured
    RubyProf::C1.hello
    sleep 1
    RubyProf.resume
    # Measured
    RubyProf::C1.hello
    result = RubyProf.stop

    printer = RubyProf::GraphPrinter.new(result)
    printer.print

    # Length should be 3:
    #   PauseTest#test_pause_resume
    #   <Class::RubyProf::C1>#hello
    #   Kernel#sleep

    methods = result.threads.first.methods.sort.reverse
    assert_equal(3, methods.length)

    # Check the names
    assert_equal('PauseTest#test_pause_resume', methods[0].full_name)
    assert_equal('<Class::RubyProf::C1>#hello', methods[1].full_name)
    assert_equal('Kernel#sleep', methods[2].full_name)

    # Check times
    assert_in_delta(0.3, methods[0].total_time, 0.01)
    assert_in_delta(0, methods[0].wait_time, 0.01)
    assert_in_delta(0, methods[0].self_time, 0.01)

    assert_in_delta(0.3, methods[1].total_time, 0.01)
    assert_in_delta(0, methods[1].wait_time, 0.01)
    assert_in_delta(0, methods[1].self_time, 0.01)

    assert_in_delta(0.3, methods[2].total_time, 0.01)
    assert_in_delta(0, methods[2].wait_time, 0.01)
    assert_in_delta(0.3, methods[2].self_time, 0.01)
  end

  def test_pause_seq
    p = RubyProf::Profile.new(RubyProf::WALL_TIME,[])
    p.start ; assert !p.paused?
    p.pause ; assert p.paused?
    p.resume; assert !p.paused?
    p.pause ; assert p.paused?
    p.pause ; assert p.paused?
    p.resume; assert !p.paused?
    p.resume; assert !p.paused?
    p.stop  ; assert !p.paused?
  end

  def test_pause_block
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])
    p.start
    p.pause
    assert p.paused?

    times_block_invoked = 0
    retval= p.resume{
      times_block_invoked += 1
      120 + times_block_invoked
    }
    assert_equal 1, times_block_invoked
    assert p.paused?

    assert_equal 121, retval, "resume() should return the result of the given block."

    p.stop
  end

  def test_pause_block_with_error
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])
    p.start
    p.pause
    assert p.paused?

    begin
      p.resume{ raise }
      flunk 'Exception expected.'
    rescue
      assert p.paused?
    end

    p.stop
  end

  def test_resume_when_not_paused
    p= RubyProf::Profile.new(RubyProf::WALL_TIME,[])
    p.start ; assert !p.paused?
    p.resume; assert !p.paused?
    p.stop  ; assert !p.paused?
  end
end
