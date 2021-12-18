import argparse
import json
import os
import subprocess

from compute_secp256k1_math import get_g_pows, get_g_pow_val, get_long

def egcd(a, b):
    if a == 0:
        return (b, 0, 1)
    else:
        g, y, x = egcd(b % a, a)
        return (g, x - (b // a) * y, y)

def modinv(a, m):
    g, x, y = egcd(a, m)
    if g != 1:
        raise Exception('modular inverse does not exist')
    else:
        return x % m

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def get_long_int(n, k, a):
    ret = []
    for idx in range(0, k):
        ret.append(a % (2 ** n))
        a = a // (2 ** n)
    return ret

TEST_BODY = '''pragma circom 2.0.2;

include "ecdsa.circom";

component main {public [privkey]} = '''
TEST_COMP_VAR = '''ECDSAPrivToPubStride({}, {}, {});
'''

TEST_STR = 'test_ecdsa'
TEST_CIRCOM_FILE = '{}.circom'.format(TEST_STR)
JS_DIR = '{}_js'.format(TEST_STR)
CPP_DIR = '{}_cpp'.format(TEST_STR)

parser = argparse.ArgumentParser()
parser.add_argument('--n', type=int, default=86)
parser.add_argument('--k', type=int, default=3)
parser.add_argument('--stride', type=int, default=8)
parser.add_argument('--privkey', type=int, default=7)
parser.add_argument('--zk_sys', type=str, default='plonk')
args = parser.parse_args()

test_str = TEST_BODY + TEST_COMP_VAR.format(args.n, args.k, args.stride)
with open(TEST_CIRCOM_FILE, 'w') as f:
    f.write(test_str)

long_priv = get_long_int(args.n, args.k, args.privkey)
input_dict = { 'privkey': [str(x) for x in long_priv] }
print('Long_priv: ', long_priv)
g_pows = get_g_pows(258)
short = get_g_pow_val(g_pows, args.privkey, args.n, args.k)
long_pub0, long_pub1 = get_long(args.n, args.k, short[0]), get_long(args.n, args.k, short[1])
print('long_pub0: ', long_pub0)
print('long_pub1: ', long_pub1)

with open('input.json', 'w') as f:
    json_str = json.dumps(input_dict)
    f.write(json_str)

subprocess.run(['circom', TEST_CIRCOM_FILE, '--r1cs', '--sym', '--c', '--wat', '--wasm'])
subprocess.run(['node',
                '{}/generate_witness.js'.format(JS_DIR),
                '{}/{}.wasm'.format(JS_DIR, TEST_STR),
                'input.json',
               '{}/witness.wtns'.format(JS_DIR)])
if args.zk_sys == 'plonk':
    subprocess.run(['snarkjs', 'plonk', 'setup', '{}.r1cs'.format(TEST_STR), 'pot22_final.ptau', '{}.zkey'.format(TEST_STR)])
    subprocess.run(['snarkjs', 'zkey', 'export', 'verificationkey', '{}.zkey'.format(TEST_STR), 'vkey.json'])
    subprocess.run(['snarkjs', 'plonk', 'prove', '{}.zkey'.format(TEST_STR), '{}/witness.wtns'.format(JS_DIR), 'proof.json', 'public.json'])
    subprocess.run(['snarkjs', 'plonk', 'verify', 'vkey.json', 'public.json', 'proof.json'])
elif args.zk_sys == 'groth16':
    subprocess.run(['snarkjs', 'groth16', 'setup', '{}.r1cs'.format(TEST_STR), 'pot22_final.ptau', '{}.zkey'.format(TEST_STR)])
    subprocess.run(['snarkjs', 'zkey', 'contribute', '{}.zkey'.format(TEST_STR), '{}1.zkey'.format(TEST_STR), '--name="asdfa"', '-v'])
    subprocess.run(['snarkjs', 'zkey', 'contribute', '{}1.zkey'.format(TEST_STR), '{}2.zkey'.format(TEST_STR), '--name="asdfa2"', '-v'])
    subprocess.run(['snarkjs', 'zkey', 'verify', '{}.r1cs'.format(TEST_STR), 'pot22_final.ptau', '{}2.zkey'.format(TEST_STR)])
    subprocess.run(['snarkjs', 'zkey', 'beacon', '{}2.zkey'.format(TEST_STR), '{}_final.zkey'.format(TEST_STR),
                    '0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f', '10', '-n="Final Beacon phase2"'])
    subprocess.run(['snarkjs', 'zkey', 'verify', '{}.r1cs'.format(TEST_STR), 'pot22_final.ptau', '{}_final.zkey'.format(TEST_STR)])
    subprocess.run(['snarkjs', 'zkey', 'export', 'verificationkey', '{}_final.zkey'.format(TEST_STR), 'vkey.json'])
    
    subprocess.run(['snarkjs', 'groth16', 'prove', '{}_final.zkey'.format(TEST_STR), '{}/witness.wtns'.format(JS_DIR), 'proof.json', 'public.json'])
    subprocess.run(['snarkjs', 'groth16', 'verify', 'vkey.json', 'public.json', 'proof.json'])
    
                
with open('public.json', 'r') as f:
    output = f.read()
    x = json.loads(output)
    
values = [int(a) for a in x]
pf_out0 = values[:args.k]
pf_out1 = values[args.k: 2 * args.k]

def list_to_val(n, x):
    ret = 0
    for idx in range(len(x)):
        ret += x[idx] * 2**(n * idx)
    return ret

print('Outputs')
correct = True
for idx in range(args.k):
    if pf_out0[idx] != long_pub0[idx]:
        correct = False
    if pf_out1[idx] != long_pub1[idx]:
        correct = False
if correct:
    print(f'{bcolors.OKGREEN} OK')
else:    
    print(f'{bcolors.FAIL}FAIL !!!!!!!!!!!!!!!!!!!!!')
print('pf_out0: ', pf_out0)
print('   out0: ', long_pub0)
print('pf_out1: ', pf_out1)
print('   out1: ', long_pub1)
