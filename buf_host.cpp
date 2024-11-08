/*
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
*/

#include <iostream>
#include <vector>
#include <chrono>
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS
#include "CL/opencl.h"

#include "ApiHandle.h"
#include "Task.h"

int main(int argc, char* argv[]) {
  // -- Common Parameters ---------------------------------------------------
  
  unsigned int numBuffers = 100;
  bool oooQueue = true;
  unsigned int processDelay = 1;

  std::vector<unsigned int> bufferSizes; // To store buffer sizes
  std::vector<double> throughputValues;   // To store throughput values
  std::vector<double> bytesPerTransferValues; // To store bytes per transfer values

  // -- Loop over size values from 8 to 19 -------------------------------
  for (int size = 8; size <= 19; ++size) {
    unsigned int bufferSize = 1 << size; // Calculate buffer size

    // -- Setup ---------------------------------------------------------------
    char *binaryName = argv[1]; // Assuming binary name is passed as first argument
    ApiHandle api(binaryName, oooQueue);

    std::cout << "Buffer Size: " << bufferSize << std::endl;
    std::cout << "Bytes per Transfer: " << bufferSize * 512 / 8 << std::endl;

    std::vector<Task> tasks(numBuffers, Task(bufferSize, processDelay));

    std::cout << "Running FPGA" << std::endl;
    auto fpga_begin = std::chrono::high_resolution_clock::now();

    // -- Execution -----------------------------------------------------------
    for (unsigned int i = 0; i < numBuffers; i++) {
      if (i < 3) {
        tasks[i].run(api);
      } else {
        tasks[i].run(api, tasks[i - 3].getDoneEv());
      }
    }
    clFinish(api.getQueue());

    // -- Testing -------------------------------------------------------------
    auto fpga_end = std::chrono::high_resolution_clock::now();

    bool outputOk = true;
    for (unsigned int i = 0; i < numBuffers; i++) {
      outputOk = tasks[i].outputOk() && outputOk;
    }
    if (!outputOk) {
      std::cout << "FAIL: Output Corrupted" << std::endl;
      return 1;
    }

    // -- Performance Statistics ----------------------------------------------
    std::chrono::duration<double> fpga_duration = fpga_end - fpga_begin;

    double total = (double)bufferSize * numBuffers * 512 / (1024.0 * 1024.0); // in Mbits
    double throughput = total / fpga_duration.count(); // in Mbits/s

    // Store values for each iteration
    bufferSizes.push_back(bufferSize);
    throughputValues.push_back(throughput);
    bytesPerTransferValues.push_back(bufferSize * 512 / 8); // in Bytes

    std::cout << "Total data: " << total << " MBits" << std::endl;
    std::cout << "FPGA Time: " << fpga_duration.count() << " s" << std::endl;
    std::cout << "FPGA Throughput: " << throughput << " MBits/s" << std::endl;
  }

  // -- Summary of Results ---------------------------------------------------
  std::cout << "\nSummary of Results:\n";
  std::cout << "Size\tBytes per Transfer\tThroughput (MBits/s)\n";
  for (size_t i = 0; i < bufferSizes.size(); ++i) {
    std::cout << (8 + i) << "\t" // Since sizes range from 8 to 19
              << bytesPerTransferValues[i] << "\t"
              << throughputValues[i] << std::endl;
  }

  return 0;
}

