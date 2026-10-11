# IP / UDP Transfer Benchmark

SwiftNetwork benchmark for measuring the performance of IP / UDP transfers.


## Usage of the Benchmark

To use this benchmark for performance measurements, make sure that you build it in release:
```
# Navigate into the SwiftNetwork directory and build everything in release:
% swift build -c release

# Navigate into the ./build/release directory and run the executable
./IPUDPTransfer
```
NOTE: Never run and measure this benchmark as a debug build the performance information will not be valid.

There are a few command line arguments that are accepted:
```
-iterations : The number of datagrams to transfer from the client to the server.
-logging : The logging handle to use. Should be `none` for performance benchmarks, but can set to `print` or `log` for debugging.
-size : The size of the datagram to transfer.
```
