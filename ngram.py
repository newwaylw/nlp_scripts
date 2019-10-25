#! /usr/bin/env python3

import re, argparse


def find_ngrams(input_list, n=3):
    return list(zip(*[input_list[i:] for i in range(n)]))


def main():

    parser = argparse.ArgumentParser(description='generate ngrams from 1 up to arity n',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('input_files', nargs='+', help='input file')
    parser.add_argument('-n', '--arity', default=3, type=int, help='max ngram arity')
    parser.add_argument('-b', '--bos', default='', help='add a begin-of-sentence symbol')
    parser.add_argument('-o', '--only', action='store_true', help='only output ngrams of arity')
    args = parser.parse_args()

    arity = args.arity

    for afile in args.input_files:
        with open(afile,'r') as f:
            for line in f:
                l = re.split('\s+', line.strip())
                #BOS is used.
                if len (args.bos) >0:
                    l.insert(0, args.bos)

                #print (l)
                # to only print arity ngram, not from 1 to arity
                if args.only:
                    ngrams = find_ngrams(l, arity)
                else:
                    ngrams = list()
                    for i in range(arity):
                        ngrams.extend(find_ngrams(l, i+1))

                for n in ngrams:
                    print(' '.join(n))


if __name__ == '__main__':
  main()
