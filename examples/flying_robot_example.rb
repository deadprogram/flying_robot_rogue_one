# Example code for flying_robot
# Uses Ruby Arduino Development to create a library/interface for Unmanned Aerial Vehicles
# Written by Ron Evans (http://deadprogrammersociety.com)
#
# In order to implement a sketch that uses the flying_robot parser, you need to implement the methods that make up its interface
# so that it will respond to the standard command set.
# 
# The following commands are supported:
# (h)ail - See if the UAV can still respond. Should send "Roger" back.
# (s)tatus - Grab a snapshot of all instrument readings plus any other status info that the UAV can support
# (e)levators - Set the elevators. The command supports two parameters:
#   direction - enter 'u' for up, 'c' for centered, or 'd' for down
#   deflection - enter an angle between 0 and 90 degrees
# (r)udder - Set the rudder. This command supports two parameters:
#   direction - enter 'l' for left, 'c' for centered, or 'r' for right
#   deflection - enter an angle between 0 and 90 degrees
# (t)hrottle - Set the throttle. This command supports two parameters:
#   direction - enter 'f' for forward, or 'r' for reverse
#   speed - enter a percentage from 0 to 100
# (i)nstruments - Read the current data for one of the installed instruments on the UAV. This command supports one parameter:
#   id - enter an integer for which instrment readings should be returned from. If there is not an instrument installed
#        for that id 'Invalid instrument' should be returned
#
class FlyingExample < ArduinoSketch
  serial_begin :rate => 9600
  
  # main command loop, required for any arduino program
  def loop
    be_flying_robot
    process_command
  end

  # flying robot interface, implement these for your own hardware set
  def hail
    serial_println "Roger"
  end
  
  def status
    serial_println "Status: operational"
  end
  
  def elevators
    print_current_command("Elevators", current_elevator_deflection)
  end
    
  def rudder
    print_current_command("Rudder", current_rudder_deflection)
  end
  
  def throttle
    print_current_command("Throttle", current_throttle_speed)
  end
    
  def instruments
    serial_print "Instruments command - request:"
    serial_println current_command_instrument
  end
end