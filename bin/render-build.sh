#!/usr/bin/env bash
# Script de build para Render
set -o errexit

bundle install
bin/rails assets:precompile
bin/rails assets:clean
