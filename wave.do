# Open a new wave window
view wave

# Clear any existing waves
delete wave *

# Add essential control signals
add wave -divider "Control"
add wave -color yellow /score_system_tb/clock
add wave -color red /score_system_tb/reset
add wave -color green /score_system_tb/game_active
add wave -color orange /score_system_tb/game_over

# Add player inputs and patterns
add wave -divider "Inputs & Patterns"
add wave -color cyan -radix binary /score_system_tb/a_input
add wave -color cyan -radix binary /score_system_tb/b_input
add wave -color magenta -radix binary /score_system_tb/pattern_a
add wave -color magenta -radix binary /score_system_tb/pattern_b
add wave -color white /score_system_tb/pattern_valid
add wave -radix unsigned /score_system_tb/pattern_timer

# Add scores and hit results
add wave -divider "Scores & Hits"
add wave -color pink -radix unsigned /score_system_tb/score_a
add wave -color pink -radix unsigned /score_system_tb/score_b
add wave -color gold -radix binary /score_system_tb/last_hit_a
add wave -color gold -radix binary /score_system_tb/last_hit_b

# Add game results
add wave -divider "Results"
add wave -color purple -radix binary /score_system_tb/winner
add wave -color blue -radix unsigned /score_system_tb/final_score_a
add wave -color blue -radix unsigned /score_system_tb/final_score_b

# Configure the display
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1
configure wave -timelineunits ns