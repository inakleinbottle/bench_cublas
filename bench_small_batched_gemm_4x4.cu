//
//

#include <benchmark/benchmark.h>
#include <thrust/device_vector.h>

#include "bench_config.cuh"
#include "small_batched_gemm.cuh"


inline constexpr auto small_batched_cooperative_gemm_4x4_rm = small_batched_cooperative_gemm<float, 4, 2, 256, Eigen::RowMajor>;
inline constexpr auto small_batched_cooperative_gemm_4x4_cm = small_batched_cooperative_gemm<float, 4, 2, 256, Eigen::ColMajor>;

static void bench_small_batched_cooperative_gemm_4x4_rm(benchmark::State &state) {
    constexpr int dim = 4;
    constexpr int size = dim*dim;
    auto n_matrices = static_cast<int>(state.range(0));

    thrust::device_vector<float> a(size * n_matrices, 1.0f);
    thrust::device_vector<float> b(size * n_matrices, 1.0f);
    thrust::device_vector<float> c(size * n_matrices, 0.0f);

    for (auto _: state) {

        const auto threads = 256;
        const auto blocks = (n_matrices + threads - 1) / threads;
        float alpha = 1.0;
        float beta = 0.0;

        small_batched_cooperative_gemm_4x4_rm<<<blocks, threads>>>(
            raw_pointer_cast(a.data()),
            raw_pointer_cast(b.data()),
            raw_pointer_cast(c.data()),
            alpha,
            beta,
            n_matrices);

        cudaDeviceSynchronize();
    }
}

BENCHMARK(bench_small_batched_cooperative_gemm_4x4_rm)->Arg(kNumMatrices);