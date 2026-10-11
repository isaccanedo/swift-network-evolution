# QUIC Stream Load Benchmark

SwiftNetwork benchmark for measuring the performance of QUIC opening many streams on a connection.

## Usage of the Benchmark

To run this benchmark you will need SwiftTLS setup and installed.

To use this benchmark for performance measurements, make sure that you build it in release:
```
# Navigate into the SwiftNetwork directory and build everything in release:
% swift build -c release

# Navigate into the ./build/release directory and run the executable
./QUICStreamLoad
```

NOTE: Never run and measure this benchmark as a debug build the performance information will not be valid.
