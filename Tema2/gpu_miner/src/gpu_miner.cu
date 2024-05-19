#include <stdio.h>
#include <stdint.h>
#include "../include/utils.cuh"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include <cuda_runtime.h>


// Function to search for all nonces from 1 through MAX_NONCE (inclusive) using CUDA Threads
__global__ void findNonce(BYTE *block_content, BYTE *block_hash, uint32_t *yes_nonce) {

    BYTE difficulty_5_zeros[SHA256_HASH_SIZE] = "0000099999999999999999999999999999999999999999999999999999999999";
    
    // Copy block_content and block_hash
    BYTE block_hash_copy[SHA256_HASH_SIZE];
    BYTE block_copy_content[BLOCK_SIZE];

    // Nonce string
    char nonce_string[NONCE_SIZE];

    // Thread index
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    
    // Stride
    int stride = blockDim.x * gridDim.x;

    for (uint32_t i_nonce = index; i_nonce <= MAX_NONCE; i_nonce += stride) {
        // Append nonce to block_content
        d_strcpy((char *)block_copy_content, (const char *)block_content);
        
        // Convert nonce to string
        intToString(i_nonce, nonce_string);

        // Append nonce to block_content (copy)
        d_strcpy((char *)block_copy_content + d_strlen((const char*)block_copy_content), nonce_string);
        
        // Apply SHA256 to block_content (copy)
        apply_sha256(block_copy_content, d_strlen((const char*)block_copy_content), block_hash_copy, 1);
        
        if (compare_hashes(block_hash_copy, difficulty_5_zeros) <= 0) {
            *yes_nonce = i_nonce;  // Store nonce
            d_strcpy((char *)block_hash, (const char *)block_hash_copy);  // Store block_hash
            break;
        }
    }
}

int main(int argc, char **argv) {
    ///// Neschimbat
    BYTE hashed_tx1[SHA256_HASH_SIZE], hashed_tx2[SHA256_HASH_SIZE], hashed_tx3[SHA256_HASH_SIZE], hashed_tx4[SHA256_HASH_SIZE],
            tx12[SHA256_HASH_SIZE * 2], tx34[SHA256_HASH_SIZE * 2], hashed_tx12[SHA256_HASH_SIZE], hashed_tx34[SHA256_HASH_SIZE],
            tx1234[SHA256_HASH_SIZE * 2], top_hash[SHA256_HASH_SIZE], block_content[BLOCK_SIZE]; 
    // Top hash 
    apply_sha256(tx1, strlen((const char*)tx1), hashed_tx1, 1);
    apply_sha256(tx2, strlen((const char*)tx2), hashed_tx2, 1);
    apply_sha256(tx3, strlen((const char*)tx3), hashed_tx3, 1);
    apply_sha256(tx4, strlen((const char*)tx4), hashed_tx4, 1);
    strcpy((char *)tx12, (const char *)hashed_tx1);
    strcat((char *)tx12, (const char *)hashed_tx2);
    apply_sha256(tx12, strlen((const char*)tx12), hashed_tx12, 1);
    strcpy((char *)tx34, (const char *)hashed_tx3);
    strcat((char *)tx34, (const char *)hashed_tx4);
    apply_sha256(tx34, strlen((const char*)tx34), hashed_tx34, 1);
    strcpy((char *)tx1234, (const char *)hashed_tx12);
    strcat((char *)tx1234, (const char *)hashed_tx34);
    apply_sha256(tx1234, strlen((const char*)tx34), top_hash, 1);

    // prev_block_hash + top_hash
    strcpy((char*)block_content, (const char*)prev_block_hash);
    strcat((char*)block_content, (const char*)top_hash);
    ///// 

    BYTE *d_block_content, *d_block_hash;
    uint32_t *d_nonce;

    // Allocate memory on the device for block_content, block_hash, and nonce
    cudaMalloc((void **)&d_block_content, BLOCK_SIZE * sizeof(BYTE));
    cudaMalloc((void **)&d_block_hash, (SHA256_HASH_SIZE + 1) * sizeof(BYTE));
    cudaMalloc((void **)&d_nonce, sizeof(uint32_t));

    // Copy block_content to device
    cudaMemcpy(d_block_content, block_content, BLOCK_SIZE * sizeof(BYTE), cudaMemcpyHostToDevice);

    // Copy block_hash and nonce back to host
    BYTE *block_hash;
    block_hash = (BYTE *)malloc((SHA256_HASH_SIZE + 1) * sizeof(BYTE));

    int blockSize = 256;
    int numBlocks = (MAX_NONCE + blockSize - 1) / blockSize;

    cudaEvent_t start, stop;
    startTiming(&start, &stop);

    // Launch kernel
    findNonce<<<numBlocks, blockSize>>>(d_block_content, d_block_hash, d_nonce);
    cudaDeviceSynchronize();

    float seconds = stopTiming(&start, &stop);

    uint32_t nonce = 0;
    
    cudaMemcpy(&nonce, d_nonce, sizeof(uint32_t), cudaMemcpyDeviceToHost);
    cudaMemcpy(block_hash, d_block_hash, SHA256_HASH_SIZE * sizeof(BYTE), cudaMemcpyDeviceToHost);

    printResult(block_hash, nonce, seconds);

    // Free device memory
    cudaFree(d_block_content);
    cudaFree(d_block_hash);
    cudaFree(d_nonce);

    // Free host memory
    free(block_hash);

    return 0;
}