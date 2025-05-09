// This code was borrowed from https://github.com/succinctlabs/zkvm-perf/blob/main/programs/rsp-risc0/src/main.rs

#![no_main]

use risc0_zkvm::{guest::env};
use rsp_client_executor::{io::ClientExecutorInput, ClientExecutor, EthereumVariant};
risc0_zkvm::guest::entry!(main);

pub fn main() {
    // Read the input.
    let input: Vec<u8> = env::read_frame();

    let input = bincode::deserialize::<ClientExecutorInput>(&input).unwrap();

    // Execute the block.
    let executor = ClientExecutor;
    let header = executor.execute::<EthereumVariant>(input).expect("failed to execute client");
    let block_hash = header.hash_slow();

    env::commit(&block_hash);
}
