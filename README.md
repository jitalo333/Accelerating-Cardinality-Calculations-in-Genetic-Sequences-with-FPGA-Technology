# Accelerating-Cardinality-Calculations-in-Genetic-Sequences-with-FPGA-Technology

Calculating cardinality on an FPGA is crucial due to its capability to process large volumes of data in parallel with high efficiency. This is particularly important in bioinformatics applications, which often involve analyzing massive genetic sequences. FPGAs allow the implementation of hardware-optimized algorithms, significantly reducing computation time compared to CPU or GPU-based solutions. This advantage is especially pronounced for tasks requiring repetitive and computationally intensive operations, such as counting unique subsequences. As a result, FPGAs deliver faster processing, lower energy consumption, and enhanced adaptability to customized workflows, making them ideal for large-scale genetic analysis.

This repository implements cardinality computation using C and then on an FPGA with the SystemVerilog hardware description language.

* File1 contains the implementation of the code in C.
* File2 uses SystemVerilog to generate the state machine that computes cardinality.
* File3 implements a simulation of the state machine, receiving DNA sequences encoded in ASCII.
