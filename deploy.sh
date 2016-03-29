#!/usr/bin/env bash
echo "Building"
bundle exec jekyll build
rsync -aPrz _site q@qumarth.me:
