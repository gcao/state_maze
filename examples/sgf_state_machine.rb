$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'state_maze/state_machine'

class SGFStateMachine < StateMaze::StateMachine
  STATE_BEGIN           = :begin
  STATE_GAME_BEGIN      = :game_begin       
  STATE_GAME_END        = :game_end
  STATE_NODE            = :game_node             
  STATE_VAR_BEGIN       = :var_begin        
  STATE_VAR_END         = :var_end     
  STATE_PROP_NAME_BEGIN = :prop_name_begin
  STATE_PROP_NAME       = :prop_name        
  STATE_VALUE_BEGIN     = :value_begin      
  STATE_VALUE           = :value            
  STATE_VALUE_ESCAPE    = :value_escape
  STATE_VALUE_END       = :value_end
  STATE_INVALID         = :invalid
  
  def initialize
    super(STATE_BEGIN)

    start_game             = lambda{ |stm| return if stm.context.nil?; stm.context.start_game                                    }
    end_game               = lambda{ |stm| return if stm.context.nil?; stm.context.end_game                                      }
    start_node             = lambda{ |stm| return if stm.context.nil?; stm.context.start_node                                    }
    start_variation        = lambda{ |stm| return if stm.context.nil?; stm.context.start_variation                               }
    store_input_in_buffer  = lambda{ |stm| return if stm.context.nil?; stm.buffer = stm.input                                    }
    append_input_to_buffer = lambda{ |stm| return if stm.context.nil?; stm.buffer += stm.input                                   }
    set_property_name      = lambda{ |stm| return if stm.context.nil?; stm.context.property_name = stm.buffer; stm.clear_buffer  }
    set_property_value     = lambda{ |stm| return if stm.context.nil?; stm.context.property_value = stm.buffer; stm.clear_buffer }
    end_variation          = lambda{ |stm| return if stm.context.nil?; stm.context.end_variation                                 }
    report_error           = lambda{ |stm| raise StateMachineError.new('SGF Error near "' + stm.input + '"')                     }

    transition STATE_BEGIN,        
                   /\(/,        
                   STATE_GAME_BEGIN,
                   start_game
                         
    transition [STATE_GAME_BEGIN, STATE_VAR_END, STATE_VALUE_END],   
                   /;/,
                   STATE_NODE,
                   start_node
    
    transition STATE_VAR_BEGIN,
                   /;/,
                   STATE_NODE
    
    transition [STATE_NODE, STATE_VAR_END, STATE_VALUE_END],
                   /\(/,        
                   STATE_VAR_BEGIN,
                   start_variation
    
    transition [STATE_NODE, STATE_VALUE_END],
                   /[a-zA-Z]/,  
                   STATE_PROP_NAME_BEGIN,
                   store_input_in_buffer
    
    transition [STATE_PROP_NAME_BEGIN, STATE_PROP_NAME],
                   /[a-zA-Z]/,
                   STATE_PROP_NAME,
                   append_input_to_buffer
    
    transition [STATE_PROP_NAME_BEGIN, STATE_PROP_NAME],    
                   /\[/,        
                   STATE_VALUE_BEGIN,
                   set_property_name
      
    transition STATE_VALUE_END,
                   /\[/,        
                   STATE_VALUE_BEGIN
                   
    transition STATE_VALUE_BEGIN,
                   /[^\]]/,
                   STATE_VALUE,
                   store_input_in_buffer
                     
    transition [STATE_VALUE_BEGIN, STATE_VALUE],
                   /\\/,
                   STATE_VALUE_ESCAPE
                     
    transition STATE_VALUE_ESCAPE,
                   /./,
                   STATE_VALUE,
                   append_input_to_buffer
                     
    transition STATE_VALUE,
                   /[^\]]/,
                   nil,
                   append_input_to_buffer
                     
    transition [STATE_VALUE_BEGIN, STATE_VALUE],        
                   /\]/,        
                   STATE_VALUE_END,
                   set_property_value
                     
    transition STATE_VAR_END,        
                   nil,        
                   STATE_GAME_END,
                   end_game
  
    transition [STATE_NODE, STATE_VALUE_END, STATE_VAR_END],
                   /\)/,        
                   STATE_VAR_END,
                   end_variation

    transition [STATE_BEGIN, STATE_GAME_BEGIN, STATE_NODE, STATE_VAR_BEGIN, STATE_VAR_END, STATE_PROP_NAME_BEGIN, STATE_PROP_NAME, STATE_VALUE_END],
                   /[^\s]/, 
                   STATE_INVALID,
                   report_error
  end
end

if __FILE__ == $0
  stm = SGFStateMachine.new
  stm.reset

  input = DATA.readlines.join

  0.upto(input.size - 1) do |i|
    stm.event(input[i,1])
  end

  stm.end
end

__END__
(;GM[1]FF[3]
RU[Japanese]SZ[19]HA[0]KM[5.5]
PW[White]
PB[Black]
GN[White (W) vs. Black (B)]
DT[1999-07-28]
SY[Cgoban 1.9.2]TM[30:00(5x1:00)];
AW[ea][eb][ec][bd][dd][ae][ce][de][cf][ef][cg][dg][eh][ci][di][bj][ej]
AB[da][db][cc][dc][cd][be][bf][ag][bg][bh][ch][dh]LB[bd:A]PL[2]
C[guff plays A and adum tenukis to fill a 1-point ko. white to kill.
]
(;W[bc];B[bb]
(;W[ca];B[cb]
(;W[ab];B[ba]
(;W[bi]
C[RIGHT
black can't push (but no such luck in the actual game)
])

(;W[ad];B[af])

(;W[ac];B[af])
)

(;W[bi];B[ac])
)

(;W[ab];B[ac]
(;W[ad];B[af])

(;W[ba];B[ad])

(;W[ca];B[ad])
)

(;W[bi];B[ac])

(;W[cb];B[ca])

(;W[ba];B[ac]
(;W[cb];B[ad])

(;W[ca];B[ad])
)

(;W[ac];B[ab];W[ca];B[ad])
)

(;W[bi];B[bc]
(;W[ah];B[ad])

(;W[ad];B[ac])
)

)