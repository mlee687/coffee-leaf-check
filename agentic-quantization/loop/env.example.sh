# Copy to env.sh and edit. Every script in this folder sources env.sh.
export LLAMA_CPP_DIR=$HOME/llama.cpp            # llama.cpp checkout 9a7570587ce908b0073a0458877205b80627f393, built with CUDA (build/bin)
export WORK=$HOME/hn04b-work                     # models/, gguf/, calib/, logs/, runs/ live here
export PY=python                                 # python 3.11 with torch, transformers>=5.5, numpy, pillow, requests
export BRACOL_ROOT=$WORK/bracol/raw              # BRACOL leaf images (folder with images/)
export HN04B_CACHE=$WORK/bracol/cache512         # preprocessed 512 px JPEGs (written by the harness)
export HN04B_RUNS=$WORK/runs                     # harness output root
export WIKITEXT=$WORK/calib/wikitext2_test.txt   # wikitext-2 raw test text, for the text-KLD check
export CALIB_TEXT=$WORK/calib/general_fwedu_c4.txt  # text calibration (FineWeb-Edu + C4) used by every build
