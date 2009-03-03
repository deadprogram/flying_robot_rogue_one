# Plugin for Ruby Arduino Development that parses the flying_robot command set from any source of input to the seriel port
# Written by Ron Evans (http://deadprogrammersociety.com) for the flying_robot project
#
# Based on code taken from the Pololu forums: http://forum.pololu.com/viewtopic.php?f=15&t=1102&p=4913&hilit=arduino#p4913
class FlyingRobot < ArduinoPlugin
  # used for parsing input commands
  external_variables "bool current_command_received_complete"
  external_variables "int current_command_length"
  external_variables "char command_buffer[120]"

  # the parsed command
  external_variables "char command_code[1]"
  external_variables "char direction_code[1]"
  external_variables "char instrument_code[1]"
  external_variables "int command_value"
  
  add_to_setup "current_command_received_complete = false;"
  
  void be_flying_robot(){}
  
  boolean current_command_received_is_complete() {
    return current_command_received_complete == true ;
  }
  
  char current_command() {
    return command_code[0];
  }

  char current_command_direction() {
    return direction_code[0];
  }

  char current_command_instrument() {
    return instrument_code[0];
  }
  
  int current_command_value() {
    return command_value ;
  }
  
  void clear_command_buffer() {
    for(int i=0; i<120; i++){
      command_buffer[i] = 0 ;
    }
    
    command_code[0] = 0 ;
    direction_code[0] = 0 ;
    instrument_code[0] = 0 ;
    current_command_length = 0 ;
    current_command_received_complete = false ;
  }
  
  void parse_command_code() {
    if(current_command_length == 0) {
      command_code[0] = 0;
    } else {
      command_code[0] = command_buffer[0];
    }
  }

  void parse_direction_code() {
    if(current_command_length >= 3) {
      direction_code[0] = command_buffer[2];
    } else {
      direction_code[0] = 0;
    }
  }

  void parse_instrument_code() {
    if(current_command_length >= 3) {
      instrument_code[0] = command_buffer[2];
    } else {
      instrument_code[0] = 0;
    }
  }

  void parse_command_value(int start) {
    if(current_command_length >= start + 1) {
      command_value = atoi(command_buffer + start);
    } else {
      command_value = 0 ;
    }
  }
  
  void get_command() {
    if(current_command_received_complete) {
      clear_command_buffer();
    }
    
    while(Serial.available() > 0) {
      command_buffer[current_command_length] = Serial.read();
      if(command_buffer[current_command_length] == '\r') {
        current_command_received_complete = true ;
        parse_command_code();
        return;
      } else {
        current_command_length++ ;
      }
    }
  }
  
  void dispatch_command() {
    if(!current_command_received_is_complete()) {
      return;
    }
    
    char cmd = current_command(); 
    
    if (cmd == 'h') {
      hail();
    } else if (cmd == 's') {  
      status();
    } else if (cmd == 'e') {
      parse_direction_code();
      parse_command_value(4);
      elevators();
    } else if (cmd == 'r') { 
      parse_direction_code();
      parse_command_value(4);
      rudder();
    } else if (cmd == 't') {
      parse_direction_code();
      parse_command_value(4);
      throttle();
    } else if (cmd == 'i') {    
      parse_instrument_code();
      instruments();
    } else {    
      Serial.println("Invalid command");
    }    
  }
  
  void process_command() {
    get_command();
    dispatch_command();
  }
end