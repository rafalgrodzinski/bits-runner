#!/bin/bash
find . -path ./build -prune -o \( -name "*.asm" -o -name "*.brc" \) -print0 | xargs -0 wc -l