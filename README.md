# Two-Player Mini Dance Dance Revolution FPGA Implementation

## Overview

This project implements a complete hardware-based two-player Dance Dance Revolution (DDR) system using the DE1-SoC FPGA board. The entire system is implemented purely in hardware with zero software abstraction layers - all processing, rendering, and audio generation is handled directly through FPGA fabric.

The system processes 8 simultaneous button inputs (4 per player) through GPIO[0-7] pins with sophisticated debouncing and active-low logic implementation for maximum noise immunity in arcade-style environments. The display system implements a split-screen VGA display at 160x120 resolution with 3-bit color depth, allowing real-time rendering of scrolling arrows, score display, and visual feedback with zero frame buffer requirements. For audio, the system generates fully synthesized game music at 90 BPM using an A minor pentatonic scale with real-time sound effect integration and multi-channel mixing.

[![Two-Player DDR FPGA Implementation](https://img.youtube.com/vi/lD32fzIGciU/0.jpg)](https://www.youtube.com/watch?v=lD32fzIGciU)

### Key Features

- **Real-time Two-Player Gameplay**: Simultaneous processing of 8 button inputs (4 per player) with sophisticated debouncing
- **Hardware-Accelerated Graphics**: Split-screen VGA display (160x120) with real-time arrow rendering and zero frame buffer
- **Synthesized Audio Engine**: Dynamic game music at 90 BPM using A minor pentatonic scale with real-time effect mixing
- **Independent Scoring System**: Perfect hit detection using 10-pixel tolerance windows with 7-segment display output
- **Modular Architecture**: Five primary subsystems with clear interfaces and independent state machines

## System Architecture

The core architecture orchestrates five primary subsystems through careful clock domain management: input processing, pattern generation, VGA display, audio synthesis, and score tracking - all synchronized to the main 50MHz clock while maintaining independent state machines. Each subsystem is implemented as a separate Verilog module with clearly defined interfaces and internal state management to ensure modularity and prevent timing conflicts between systems.

The system employs a master reset signal (SW[9]) that propagates to all subsystems ensuring synchronized startup and error recovery capabilities. All timing-critical operations are synchronized to the 50MHz system clock with appropriate clock enables and dividers for different timing domains (display refresh, audio sampling, button debouncing).

## Technical Implementation

### Input Processing System

The hardware interface processes 8 buttons through GPIO[0-7] mapped specifically for optimal player ergonomics. Player A's controls are mapped to GPIO[1,3,5,7] controlling [left,up,right,down] respectively, while Player B uses GPIO[0,2,4,6] in the same configuration. The system implements active-low logic with pull-up resistors and additional 10kΩ pull-down resistors for enhanced noise immunity.

The debouncing implementation is particularly thorough, using a multi-stage approach that begins with a dual-flip-flop synchronizer to prevent metastability. This is followed by a 20ms stability counter implemented as a 500,000 cycle counter at 50MHz. The counter only increments when input remains stable and resets on any transition, with separate counters maintained for each button to ensure independent processing.

For immediate visual feedback, the system utilizes the onboard LEDs: LEDR[3:0] displays Player A's debounced inputs in real-time, while LEDR[7:4] mirrors Player B's debounced states. Additional indicator LEDs (LEDR[8:9]) show general button activity for each player, allowing visual verification of the entire input processing pipeline.

### Audio Synthesis Architecture

The audio system implements a sophisticated real-time synthesis engine that generates both melodic content and percussion. The base tempo is maintained at 90 BPM through precise timing parameters, with the melody following an A minor pentatonic scale for optimal gameplay feel. The frequency values for each note have been carefully calculated to ensure perfect pitch:

```verilog
parameter A4  = 19'd45455;  // A4  (~440.00 Hz)
parameter C5  = 19'd38223;  // C5  (~523.25 Hz)
parameter D5  = 19'd34053;  // D5  (~587.33 Hz)
parameter E5  = 19'd30337;  // E5  (~659.26 Hz)
parameter G5  = 19'd25510;  // G5  (~783.99 Hz)
parameter A5  = 19'd22727;  // A5  (~880.00 Hz)
```

The drum synthesis system employs three distinct voices: kick drum, snare, and hi-hat. Each percussion voice has carefully tuned envelope parameters for attack and decay, creating realistic drum sounds without sample playback. The kick drum uses a low-frequency oscillator with heavy envelope shaping, while the snare combines noise generation through an LFSR with bandpass filtering. The hi-hat utilizes high-frequency noise with a short decay envelope for a crisp sound.

### Graphics Pipeline

The VGA subsystem implements a zero frame buffer architecture that generates all visual elements in real-time through combinational logic. Operating at 160x120 resolution with 3-bit color depth, the system divides the screen into two equal sections for both players while maintaining smooth 60Hz refresh rates.

The rendering pipeline implements a sophisticated priority-based pixel selection system with multiple layers:
1. The background layer provides the base game environment
2. Score boxes and target zones are rendered with distinct visual properties for clear player feedback
3. Arrows are drawn with directional color coding and smooth scrolling mechanics

Arrow sprites are generated through precise boolean equations that define each pixel position, eliminating the need for sprite storage in memory. The system tracks positions for 8 simultaneous arrows (4 per player) while maintaining perfect synchronization with the gameplay mechanics.

## Performance and Technical Specifications

The system operates on a 50MHz master clock with carefully managed timing domains for different subsystems. Input processing maintains a maximum latency of 20ms through the debouncing system, while the display refreshes at a consistent 60Hz. The audio system operates at 44.1kHz sample rate with 32-bit internal processing for high-quality sound reproduction.

The pattern generation system creates arrow patterns at 0.5-second intervals, with an advanced distribution algorithm that ensures engaging gameplay while maintaining fairness. Hit detection utilizes a ±10 pixel window centered on the target zone, providing a balanced challenge level that rewards precise timing.

## Academic Integrity Notice

This project was created as coursework for ECE241 at the University of Toronto. The code and documentation are provided for reference only and are not licensed for use, modification, or distribution. All rights reserved.
