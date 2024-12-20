# Update system package data
!sudo apt update

# Install OpenCV development package to use OpenCV
!sudo apt install libopencv-dev

# Install nvcc extension through GitHub to Google Colab
!pip install git+https://github.com/andreinechaev/nvcc4jupyter.git

# Commented out IPython magic to ensure Python compatibility.
# Load the installed nvcc extension into Google Colab
# %reload_ext nvcc4jupyter.plugin

# Display the installed nvcc version
!nvcc --version

# Install OpenCV Python library for use
!pip install opencv-python

# Import required libraries
import cv2
import numpy as np
from matplotlib import pyplot as plt

# Create a function to display images
def imshow(title="Image", image=None, size=10):
    w, h = image.shape[0], image.shape[1]
    aspect_ratio = w/h  # To maintain the original aspect ratio
    plt.figure(figsize=(size * aspect_ratio, size))
    plt.imshow(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    plt.title(title)
    plt.show()

# Read and display the image to be used
image = plt.imread("/content/aang.jpg")
plt.imshow(image)
plt.show()

# CUDA kernel for 90-degree rotation and translation
code = '''#include <opencv2/opencv.hpp>
#include <cuda_runtime.h>
#include <stdio.h>

// CUDA Kernel for image translation
__global__ void translateImage(unsigned char *input, unsigned char *output, int width, int height, int tx, int ty) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        int newX = x + tx;
        int newY = y + ty;
        if (newX < width && newY < height) {
            int inputIdx = (y * width + x) * 3;
            int outputIdx = (newY * width + newX) * 3;

            output[outputIdx] = input[inputIdx];
            output[outputIdx + 1] = input[inputIdx + 1];
            output[outputIdx + 2] = input[inputIdx + 2];
        }
    }
}

// Kernel for 90-degree rotation of color image
__global__ void rotate90(unsigned char *input, unsigned char *output, int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        // New coordinates for 90-degree clockwise rotation
        int new_x = y;
        int new_y = width - 1 - x;

        // Calculate the offset for the color image
        int inputIdx = (y * width + x) * 3;  // 3 for color image (RGB)
        int outputIdx = (new_y * height + new_x) * 3;

        // Copy data for each channel (R, G, B)
        output[outputIdx] = input[inputIdx];         // R
        output[outputIdx + 1] = input[inputIdx + 1]; // G
        output[outputIdx + 2] = input[inputIdx + 2]; // B
    }
}

int main() {
    cv::Mat input_image = cv::imread("/content/aang.jpg", cv::IMREAD_COLOR);
    if (input_image.empty()) {
        printf("Failed to read the input image.");
        return -1;
    }

    int width = input_image.cols;
    int height = input_image.rows;

    unsigned char *h_input = input_image.data;
    unsigned char *h_output_trans = new unsigned char[width * height * 3]; // Buffer for translation result
    unsigned char *h_output_rot = new unsigned char[width * height * 3];   // Buffer for rotation result

    unsigned char *d_input, *d_output;
    cudaMalloc((void**)&d_input, width * height * 3 * sizeof(unsigned char));
    cudaMalloc((void**)&d_output, width * height * 3 * sizeof(unsigned char));

    cudaMemcpy(d_input, h_input, width * height * 3 * sizeof(unsigned char), cudaMemcpyHostToDevice);

    // Set translation values (e.g., shift by half the width and height of the image)
    int tx = width / 4;  // Horizontal translation
    int ty = height / 4; // Vertical translation

    // Set block and grid size
    dim3 blockSize(16, 16);
    dim3 gridSize((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);

    // Call the kernel for image translation
    translateImage<<<gridSize, blockSize>>>(d_input, d_output, width, height, tx, ty);

    // Copy translation result to host
    cudaMemcpy(h_output_trans, d_output, width * height * 3 * sizeof(unsigned char), cudaMemcpyDeviceToHost);

    // Create output image for translation with original size
    cv::Mat output_trans_image(height, width, CV_8UC3, h_output_trans);
    cv::imwrite("/content/translated_image.jpg", output_trans_image);
    printf("Translated image saved as translated_image.jpg.");

    // Call the kernel for 90-degree rotation
    rotate90<<<gridSize, blockSize>>>(d_input, d_output, width, height);

    // Copy rotation result to host
    cudaMemcpy(h_output_rot, d_output, width * height * 3 * sizeof(unsigned char), cudaMemcpyDeviceToHost);

    // Create output image for rotation with new size
    cv::Mat output_rot_image(width, height, CV_8UC3, h_output_rot); // New image size after rotation
    cv::imwrite("/content/trans_rotated_90.jpg", output_rot_image);
    printf("Rotated image saved as trans_rotated_90.jpg.");

    // Free memory
    cudaFree(d_input);
    cudaFree(d_output);
    delete[] h_output_trans;
    delete[] h_output_rot;

    return 0;
}

'''

# Save translation code to file translationimg.cu
with open('translationimg.cu', 'w') as file:
    file.write(code)

# Save rotation code to file rotation90.cu
with open('rotation90.cu', 'w') as file:
    file.write(code)

# Compile translation code using CUDA nvcc
!nvcc -o translation translationimg.cu `pkg-config --cflags --libs opencv4` -diag-suppress 611

# Run CUDA code for translation
!./translation

# Compile rotation code using CUDA nvcc
!nvcc -o rotation rotation90.cu `pkg-config --cflags --libs opencv4` -diag-suppress 611

# Run CUDA code for rotation
!./rotation

import time

# Start the timing
start_time = time.time()

# Run CUDA translation code
!./translation
image_trans = plt.imread("/content/translated_image.jpg")
plt.imshow(image_trans)
plt.show()

!./rotation
image_rotate = plt.imread("/content/trans_rotated_90.jpg")
plt.imshow(image_rotate)
plt.show()

# End the timing
end_time = time.time()

# Display the execution time
print(f"Execution time: {end_time - start_time} seconds")
