import argparse
import json
import os
import subprocess

P = 2**256 - 2**32 - 977
N = 115792089237316195423570985008687907852837564279074904382605163141518161494337
A = 0
B = 7
Gx = 55066263022277343669578718895168534326250603453777594175500187360389116729240
Gy = 32670510020758816978083085130507043184471273380659243275938904335757337482424

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

def get_long(n, k, x):
    ret = []
    for idx in range(k):
        ret.append(x % (2 ** n))
        x = x // (2 ** n)
    return ret

def add(x1, y1, x2, y2):
    lamb = ((y2 - y1) * modinv(P + x2 - x1, P)) % P
    retx = (P + lamb ** 2 - x1 - x2) % P
    rety = (P + lamb * (x1 - retx) - y1) % P
    return retx, rety

def double(x, y):
    lamb = (3 * (x ** 2) * modinv(2 * y, P)) % P
    retx = (lamb ** 2 - 2 * x) % P
    rety = (lamb * (x - retx) - y) % P
    return retx, rety

def get_g_pows(exp):
    g_pows = []
    curr_x, curr_y = Gx, Gy
    for idx in range(exp):
        g_pows.append((curr_x, curr_y))
        curr_x, curr_y = double(curr_x, curr_y)
    return g_pows

def get_binary(x):
    ret = []
    while x > 0:
        ret.append(x % 2)
        x = x // 2
    return ret

def get_g_pow_val(g_pows, exp, n, k):
    binary = get_binary(exp)
    is_nonzero = False
    curr_sum = None
    for idx, val in enumerate(binary):
        if val != 0:
            if not is_nonzero:
                is_nonzero = True 
                curr_sum = g_pows[idx]
            else:
                curr_sum = add(curr_sum[0], curr_sum[1], g_pows[idx][0], g_pows[idx][1])
    return curr_sum            


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
    subprocess.run(['npx', 'snarkjs', 'plonk', 'setup', '{}.r1cs'.format(TEST_STR), 'pot22_final.ptau', '{}.zkey'.format(TEST_STR)])
    subprocess.run(['npx', 'snarkjs', 'zkey', 'export', 'verificationkey', '{}.zkey'.format(TEST_STR), 'vkey.json'])
    subprocess.run(['npx', 'snarkjs', 'plonk', 'prove', '{}.zkey'.format(TEST_STR), '{}/witness.wtns'.format(JS_DIR), 'proof.json', 'public.json'])
    subprocess.run(['npx', 'snarkjs', 'plonk', 'verify', 'vkey.json', 'public.json', 'proof.json'])
elif args.zk_sys == 'groth16':
    subprocess.run(['npx', 'snarkjs', 'groth16', 'setup', '{}.r1cs'.format(TEST_STR), 'pot22_final.ptau', '{}.zkey'.format(TEST_STR)])
    subprocess.run(['npx', 'snarkjs', 'zkey', 'verify', '{}.r1cs'.format(TEST_STR), 'pot22_final.ptau', '{}.zkey'.format(TEST_STR)])
    subprocess.run(['npx', 'snarkjs', 'zkey', 'beacon', '{}2.zkey'.format(TEST_STR), '{}_final.zkey'.format(TEST_STR),
                    '0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f', '10', '-n="Final Beacon phase2"'])
    subprocess.run(['npx', 'snarkjs', 'zkey', 'verify', '{}.r1cs'.format(TEST_STR), 'pot22_final.ptau', '{}_final.zkey'.format(TEST_STR)])
    subprocess.run(['npx', 'snarkjs', 'zkey', 'export', 'verificationkey', '{}_final.zkey'.format(TEST_STR), 'vkey.json'])
    
    subprocess.run(['npx', 'snarkjs', 'groth16', 'prove', '{}_final.zkey'.format(TEST_STR), '{}/witness.wtns'.format(JS_DIR), 'proof.json', 'public.json'])
    subprocess.run(['npx', 'snarkjs', 'groth16', 'verify', 'vkey.json', 'public.json', 'proof.json'])
    
                
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
