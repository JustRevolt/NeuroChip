# Tensor core

Prototype of Tensor core for CNN processing acceleration

----

Table of Contents:

1. [Description](#Tensor-core-Description)
    1. [Tensor core architecture](#Tensor-core-architecture)
    2. [Microarchitecture of tensor core computing unit sub-blocks](#Tensor-core-computing-unit-microarchitecture)
2. [Tensor core dir structure](#Tensor-core-dir-structure)
3. [Simulation instruction](#Tensor-core-Simulation-instruction)

## Description <a name="Tensor-core-Description"></a>

### Tensor core architecture. <a name="Tensor-core-architecture"></a>

<img alt="tensor core architecture with fully separated bus" src="doc/imgs/architecture-fully_separated_bus_Mem-CU.png" width="800"/>

### Microarchitecture of tensor core computing unit sub-blocks: <a name="Tensor-core-computing-unit-microarchitecture"></a>

- __Systolic array microarchitecture__

<img alt="Systolic array microarchitecture" src="doc/imgs/microarchitecture-Systolic_Array.png" width="600"/>

- __MAC sub-block microarchitecture__

<img alt="MAC microarchitecture" src="doc/imgs/microarchitecture-MAC.png" width="400"/>

- __Accumulators sub-block microarchitecture__

<img alt="Accumulators microarchitecture" src="doc/imgs/microarchitecture-Accumulators.png" width="700"/>

- __Offsets sub-block microarchitecture__

<img alt="Offsets microarchitecture" src="doc/imgs/microarchitecture-Offsets.png" width="500"/>

- __Activation sub-block microarchitecture__

<img alt="Activation microarchitecture" src="doc/imgs/microarchitecture-Activation.png" width="400"/>

- __Polling sub-block microarchitecture__

<img alt="Polling microarchitecture" src="doc/imgs/microarchitecture-Polling.png" width="400"/>


## Tensor core dir structure <a name="Tensor-core-dir-structure"></a>

`doc` - documentation files for used libraries and useful information files

`src` - source files of neural processor modules

`tb` - testbench files for testing neural processor modules in a simulation environment

`xc7a100tcsg324_project` - Xilinx Vivado project for xc7a100tcsg324 FPGA

`xc7a100tcsg324_project/waveform_cfg` - Xilinx Vivado waveform configuration files for all testbenches

## Simulation instruction <a name="Tensor-core-Simulation-instruction"></a>

Xilinx Vivado CAD verison required: v2019.1 (64-bit)

1. Download and install Xilinx Vivado CAD
2. Open Vivado project `/xc7a100tcsg324_project/xc7a100tcsg324_project.xpr`
3. Select necessary testbench file and "Set as top"
4. Start "Behavioral Simulation"
5. The test results are displayed in the TCL console