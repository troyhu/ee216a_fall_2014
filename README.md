# UCLA EE216A project:
# Sprite Game Display Engine

For both plan 1 and plan 2, area is around 9.4e+04 um^2 and power is 1.65e+05 uW. High area and high power cost are mainly because large numbers of registers are used to read and store object information in ROMs.

In plan 3, I eliminated all those buffer regs, which instead increased complexity when judging overlapping and writing frame buffer since continuously reading ROMs is required. After synthesis, area is 6.6e+03 um^2 and power is 1.26e+04 uW. Compared with former two plans, both area and power are reduced by 15 times.


