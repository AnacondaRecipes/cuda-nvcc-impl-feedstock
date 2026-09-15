// Force NVCC device-code compilation; this kernel is never launched, so the
// resulting executable remains suitable for GPU-less CI.
__global__ void noop_kernel() {}

int main() {
    return 0;
}
