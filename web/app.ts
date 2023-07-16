// Parcel should inline the fs module. See https://github.com/parcel-bundler/parcel/issues/8256
import { readFileSync } from 'fs';

// Define global buffer size
const BUFFER_SIZE = 1000; 

const shader = readFileSync('./shader.wgsl', 'utf8');

async function init() {
    // 1: request adapter and device
    // @ts-ignore
    if (!navigator.gpu) {
        throw Error('WebGPU not supported.');
    }

    // @ts-ignore
    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) {
        throw Error('Couldn\'t request WebGPU adapter.');
    }

    const device = await adapter.requestDevice();
    console.log(device);

    // 2: Create a shader module from the shader template literal
    const shaderModule = device.createShaderModule({
        code: shader
    });

    // 3: Create an output buffer to read GPU calculations to, and a staging buffer to be mapped for JavaScript access

    const output = device.createBuffer({
        size: BUFFER_SIZE,
        // @ts-ignore
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC
    });

    const stagingBuffer = device.createBuffer({
        size: BUFFER_SIZE,
        // @ts-ignore
        usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST
    });

    // 4: Create a GPUBindGroupLayout to define the bind group structure, create a GPUBindGroup from it,
    // then use it to create a GPUComputePipeline

    const bindGroupLayout =
        device.createBindGroupLayout({
            entries: [{
                binding: 0,
                // @ts-ignore
                visibility: GPUShaderStage.COMPUTE,
                buffer: {
                    type: "storage"
                }
            }]
        });

    const bindGroup = device.createBindGroup({
        layout: bindGroupLayout,
        entries: [{
            binding: 0,
            resource: {
                buffer: output,
            }
        }]
    });

    const computePipeline = device.createComputePipeline({
        layout: device.createPipelineLayout({
            bindGroupLayouts: [bindGroupLayout]
        }),
        compute: {
            module: shaderModule,
            entryPoint: 'main'
        }
    });

    // 5: Create GPUCommandEncoder to issue commands to the GPU
    const commandEncoder = device.createCommandEncoder();

    // 6: Initiate render pass
    const passEncoder = commandEncoder.beginComputePass();

    // 7: Issue commands
    passEncoder.setPipeline(computePipeline);
    passEncoder.setBindGroup(0, bindGroup);
    passEncoder.dispatchWorkgroups(Math.ceil(BUFFER_SIZE / 64));

    // End the render pass
    passEncoder.end();

    // Copy output buffer to staging buffer
    commandEncoder.copyBufferToBuffer(
        output,
        0, // Source offset
        stagingBuffer,
        0, // Destination offset
        BUFFER_SIZE
    );

    // 8: End frame by passing array of command buffers to command queue for execution
    device.queue.submit([commandEncoder.finish()]);

    // map staging buffer to read results back to JS
    await stagingBuffer.mapAsync(
        // @ts-ignore
        GPUMapMode.READ,
        0, // Offset
        BUFFER_SIZE // Length
    );

    const copyArrayBuffer = stagingBuffer.getMappedRange(0, BUFFER_SIZE);
    const data = copyArrayBuffer.slice();
    stagingBuffer.unmap();
    const dataBuf = new Uint8Array(data);
    const codeOutput = document.getElementById("output");
    codeOutput.innerHTML = dataBuf.toString();
}

const main = async () => {
    await init()
}

main()
