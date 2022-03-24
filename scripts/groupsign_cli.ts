const snarkjs = require('snarkjs');
const readline = require('readline');
const util = require('util');
const { BigNumber, Wallet } = require('ethers');
const fs = require('fs');
const wc = require('../build/groupsig/groupsig_js/witness_calculator.js');

const wasm = './build/groupsig/groupsig_js/groupsig.wasm';
const zkey = './build/groupsig/groupsig.zkey';
const vkey = './build/groupsig/vkey.json';
const wtnsFile = './build/groupsig/witness.wtns';

function isHex(str: string): boolean {
    if (str.length % 2 !== 0) return false;
    if (str.slice(0, 2) !== '0x') return false;
    const allowedChars = '0123456789abcdefABCDEF';
    for (let i = 2; i < str.length; i++)
        if (!allowedChars.includes(str[i]))
            return false;
    return true;
}

function isValidPrivateKey(privkey: string): boolean {
    if (privkey.length !== 66) return false;
    if (!isHex(privkey)) return false;
    return true;
}

function isValidAddr(addr: string): boolean {
    if (addr.length !== 42) return false;
    if (!isHex(addr)) return false;
    return true;
}

function toWordArray(x: bigint, nWords: number, bitsPerWord: number): string[] {
    const res: string[] = [];
    let remaining = x;
    const base = 2n ** BigInt(bitsPerWord);
    for (let i = 0; i < nWords; i++) {
        res.push((remaining % base).toString());
        remaining /= base;
    }
    if (remaining !== 0n) {
        throw new Error(`can't represent ${x} as ${nWords} ${bitsPerWord}-bit words`);
    }
    return res;
}

async function generateWitness(inputs: any) {
    const buffer = fs.readFileSync(wasm);
    const witnessCalculator = await wc(buffer);
    const buff = await witnessCalculator.calculateWTNSBin(inputs, 0);
    fs.writeFileSync(wtnsFile, buff);
}

async function run() {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

    const privKeyStr = await new Promise<string>((res) => {
        rl.question("Enter an ETH private key:\n", (ans: string) => {
            res(ans);
        })
    })
    const wallet = new Wallet(privKeyStr);
    console.log(`Your address is: ${wallet.address}`);

    const groupAddr1 = await new Promise<string>((res) => {
        rl.question("Enter address 1 for your group:\n", (ans: string) => {
            res(ans);
        })
    });
    if (!isValidAddr(groupAddr1)) throw new Error('not a valid ETH address');
    const groupAddr2 = await new Promise<string>((res) => {
        rl.question("Enter address 2 for your group:\n", (ans: string) => {
            res(ans);
        })
    });
    if (!isValidAddr(groupAddr2)) throw new Error('not a valid ETH address');

    const idx1 = Math.floor(Math.random() * 3);
    let idx2 = Math.floor(Math.random() * 2);
    if (idx2 >= idx1) idx2++;
    const idx3 = 3 - idx1 - idx2;

    const groupAddresses = [];
    groupAddresses[idx1] = BigInt(wallet.address);
    groupAddresses[idx2] = BigInt(groupAddr1);
    groupAddresses[idx3] = BigInt(groupAddr2);

    const msg = await new Promise<string>((res) => {
        rl.question("Enter a message to sign (number between 0 and babyjubjubprime - 1):\n", (ans: string) => {
            res(ans);
        })
    });

    const input = {
        privkey: toWordArray(BigInt(privKeyStr), 4, 64),
        addr1: groupAddresses[0],
        addr2: groupAddresses[1],
        addr3: groupAddresses[2],
        msg
    };

    console.log(input);

    // for some reason fullprove is broken currently: https://github.com/iden3/snarkjs/issues/107
    console.log('generating witness...');
    const wtnsStart = Date.now();
    await generateWitness(input);
    console.log(`generated witness. took ${Date.now() - wtnsStart}ms`);

    const pfStart = Date.now();
    console.log('generating proof...');
    const { proof, publicSignals } = await snarkjs.groth16.prove(zkey, wtnsFile);
    console.log(proof);
    console.log(publicSignals);
    console.log(`generated proof. took ${Date.now() - pfStart}ms`);

    const verifyStart = Date.now();
    console.log('verifying proof...');

    const vkeyJson = JSON.parse(fs.readFileSync(vkey));
    const res = await snarkjs.groth16.verify(vkeyJson, publicSignals, proof);
    if (res === true) {
        console.log("Verification OK");
        console.log(`verified that one of these addresses signed ${publicSignals[4]}:`);
        console.log(BigNumber.from(publicSignals[1]).toHexString());
        console.log(BigNumber.from(publicSignals[2]).toHexString());
        console.log(BigNumber.from(publicSignals[3]).toHexString());
    } else {
        console.log("Invalid proof");
    }
    console.log(`verification took ${Date.now() - verifyStart}ms`);
    
    process.exit(0);
}

run();
