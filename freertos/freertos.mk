# The source files to build for FreeRTOS to work
C_SOURCES += $(wildcard $(RTOSDIR)/src/*.c)
C_SOURCES += $(RTOSDIR)/src/portable/GCC/ARM_CM4F/port.c

# The includes to use in building FreeRTOS
INCDIRS   += $(RTOSDIR)/src/include
INCDIRS   += $(RTOSDIR)/src/portable/GCC/ARM_CM4F

