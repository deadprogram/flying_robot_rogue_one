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