# QUIC Handshake Benchmark

SwiftNetwork benchmark for measuring the performance of QUIC Handshakes.

## Usage of the Benchmark

To run this benchmark you will need SwiftTLS setup and installed.

To use this benchmark for performance measurements, make sure that you build it in release:
```
# Navigate into the SwiftNetwork directory and build everything in release:
% swift build -c release

# Navigate into the ./build/release directory and run the executable
./QUICHandshake
```
NOTE: Never run and measure this benchmark as a debug build the performance information will not be valid.

There are a few command line arguments that are accepted:
```
-iterations : The number of handshakes to run in the benchmark.
-logging : The logging handle to use. Should be `none` for performance benchmarks, but can set to `print` or `log` for debugging.
```
