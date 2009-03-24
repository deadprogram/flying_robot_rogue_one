# Plugin for Ruby Arduino Development that allows use of the Pololu 
# Written by Ron Evans (http://deadprogrammersociety.com) for the flying_robot project
#
# Based on code taken from the Pololu forums: http://forum.pololu.com/viewtopic.php?f=15&t=1102&p=4913&hilit=arduino#p4913
class PololuIrReceiver < ArduinoPlugin
  external_variables "bool pololu_ir_init_complete"
  add_to_setup "pololu_ir_init_complete = false;"
  
  void read_ir_receiver(int front_pin, int right_pin, int back_pin, int left_pin)
  {

  }
  
end
