onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /QuadCopter_tb/iDUT/clk
add wave -noupdate /QuadCopter_tb/iDUT/RST_n
add wave -noupdate /QuadCopter_tb/iDUT/RX
add wave -noupdate /QuadCopter_tb/iDUT/MISO
add wave -noupdate /QuadCopter_tb/iDUT/INT
add wave -noupdate /QuadCopter_tb/iDUT/SS_n
add wave -noupdate /QuadCopter_tb/iDUT/SCLK
add wave -noupdate /QuadCopter_tb/iDUT/MOSI
add wave -noupdate /QuadCopter_tb/iDUT/TX
add wave -noupdate /QuadCopter_tb/iDUT/FRNT
add wave -noupdate /QuadCopter_tb/iDUT/BCK
add wave -noupdate /QuadCopter_tb/iDUT/LFT
add wave -noupdate /QuadCopter_tb/iDUT/RGHT
add wave -noupdate /QuadCopter_tb/iDUT/cmd_rdy
add wave -noupdate /QuadCopter_tb/iDUT/cmd
add wave -noupdate /QuadCopter_tb/iDUT/data
add wave -noupdate /QuadCopter_tb/iDUT/clr_cmd_rdy
add wave -noupdate /QuadCopter_tb/iDUT/resp
add wave -noupdate /QuadCopter_tb/iDUT/send_resp
add wave -noupdate /QuadCopter_tb/iDUT/resp_sent
add wave -noupdate /QuadCopter_tb/iDUT/vld
add wave -noupdate -radix decimal /QuadCopter_tb/iDUT/ptch
add wave -noupdate -radix decimal /QuadCopter_tb/iDUT/roll
add wave -noupdate -radix decimal /QuadCopter_tb/iDUT/yaw
add wave -noupdate /QuadCopter_tb/iDUT/d_ptch
add wave -noupdate /QuadCopter_tb/iDUT/d_roll
add wave -noupdate /QuadCopter_tb/iDUT/d_yaw
add wave -noupdate /QuadCopter_tb/iDUT/thrst
add wave -noupdate /QuadCopter_tb/iDUT/rst_n
add wave -noupdate /QuadCopter_tb/iDUT/strt_cal
add wave -noupdate /QuadCopter_tb/iDUT/inertial_cal
add wave -noupdate /QuadCopter_tb/iDUT/motors_off
add wave -noupdate /QuadCopter_tb/iDUT/cal_done
add wave -noupdate /QuadCopter_tb/iDUT/frnt_spd
add wave -noupdate /QuadCopter_tb/iDUT/bck_spd
add wave -noupdate /QuadCopter_tb/iDUT/lft_spd
add wave -noupdate /QuadCopter_tb/iDUT/rght_spd
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {764 ns}
