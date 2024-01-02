# Benchmarks

Benchmarks for this plugin were carried out to assess its performance against `membrane_g711_ffmpeg_plugin`:
- `membrane_g711_plugin` is a pure Elixir implementation of the G711 A-law encoder/decoder,
- `membrane_g711_ffmpeg_plugin` uses Erlang NIFs to run C code leveraging the FFmpeg (libavcodec, libavutil) API.

In the pure Elixir implementation, three different variants of G711 LUT (look-up table) storage were tested:
- Generated at compile time, stored as pattern-matched functions,
- Generated at compile time, stored as a map in a module attribute,
- Generated at runtime (once), stored as a map in state.

The tests were executed with three different input sizes: 160 B, 1024 B, 20480 B
(doubled for raw s16le audio in comparison to G711 A-law audio).

## Running

To run the benchmarks yourself, execute the following commands in the root of this repo:
```
MIX_ENV=benchmark mix compile
MIX_ENV=benchmark mix run benchmarks/run_benchmarks.exs
```

## Results

Overall, users seeking speed for large and medium-sized data should generally use `membrane_g711_ffmpeg_plugin`.
However, when dealing with small input sizes (such as RTP payloads), `membrane_g711_plugin` offers a performance advantage.

### Setup

```
Operating System: macOS
CPU Information: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
Number of Available Cores: 16
Available memory: 32 GB
Elixir 1.14.5
Erlang 26.0.2
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 1
```

### Encoding benchmark

```
##### With input Big 40960 B #####
Name                                 ips        average  deviation         median         99th %
FFmpeg NIFs                      50.45 K       19.82 μs    �68.96%       16.01 μs       82.89 μs
Pattern match function LUT        2.06 K      485.14 μs    �17.35%      455.01 μs      856.95 μs
Module attribute map LUT          1.44 K      696.82 μs    �22.67%      631.47 μs     1355.40 μs
Map LUT in state                  1.30 K      767.54 μs    �38.08%      681.61 μs     1712.21 μs

Comparison:
FFmpeg NIFs                      50.45 K
Pattern match function LUT        2.06 K - 24.47x slower +465.32 μs
Module attribute map LUT          1.44 K - 35.15x slower +677.00 μs
Map LUT in state                  1.30 K - 38.72x slower +747.72 μs

##### With input Medium 2048 B #####
Name                                 ips        average  deviation         median         99th %
FFmpeg NIFs                     174.74 K        5.72 μs   �233.55%        4.61 μs       33.96 μs
Pattern match function LUT       45.04 K       22.20 μs    �33.74%       20.72 μs       60.07 μs
Module attribute map LUT         28.11 K       35.57 μs    �37.02%       30.98 μs       98.14 μs
Map LUT in state                 25.29 K       39.55 μs    �38.85%       33.81 μs      102.76 μs

Comparison:
FFmpeg NIFs                     174.74 K
Pattern match function LUT       45.04 K - 3.88x slower +16.48 μs
Module attribute map LUT         28.11 K - 6.22x slower +29.85 μs
Map LUT in state                 25.29 K - 6.91x slower +33.82 μs

##### With input Small 320 B (encoded into 160 B, typical RTP payload size) #####
Name                                 ips        average  deviation         median         99th %
Pattern match function LUT      374.72 K        2.67 μs    �91.35%        2.37 μs        5.09 μs
Module attribute map LUT        232.06 K        4.31 μs    �61.50%        3.96 μs       19.83 μs
Map LUT in state                210.75 K        4.74 μs    �81.02%        4.13 μs       26.63 μs
FFmpeg NIFs                     203.68 K        4.91 μs   �342.30%        4.14 μs       27.12 μs

Comparison:
Pattern match function LUT      374.72 K
Module attribute map LUT        232.06 K - 1.61x slower +1.64 μs
Map LUT in state                210.75 K - 1.78x slower +2.08 μs
FFmpeg NIFs                     203.68 K - 1.84x slower +2.24 μs
```

### Decoding benchmark

```
##### With input Big 20480 B #####
Name                                 ips        average  deviation         median         99th %
FFmpeg NIFs                      55.70 K       17.95 μs   �151.16%       14.43 μs       74.33 μs
Pattern match function LUT        2.21 K      451.74 μs    �16.46%      431.20 μs      788.24 μs
Module attribute map LUT          1.86 K      537.23 μs    �13.26%      517.09 μs      870.58 μs
Map LUT in state                  1.75 K      570.90 μs    �18.32%      533.12 μs     1032.99 μs

Comparison:
FFmpeg NIFs                      55.70 K
Pattern match function LUT        2.21 K - 25.16x slower +433.79 μs
Module attribute map LUT          1.86 K - 29.92x slower +519.28 μs
Map LUT in state                  1.75 K - 31.80x slower +552.94 μs

##### With input Medium 1024 B #####
Name                                 ips        average  deviation         median         99th %
FFmpeg NIFs                     153.87 K        6.50 μs   �187.14%        5.12 μs       38.65 μs
Pattern match function LUT       47.04 K       21.26 μs    �28.09%       20.07 μs       53.88 μs
Module attribute map LUT         38.33 K       26.09 μs    �30.02%       24.57 μs       65.53 μs
Map LUT in state                 37.94 K       26.36 μs    �27.31%       25.10 μs       63.65 μs

Comparison:
FFmpeg NIFs                     153.87 K
Pattern match function LUT       47.04 K - 3.27x slower +14.76 μs
Module attribute map LUT         38.33 K - 4.01x slower +19.59 μs
Map LUT in state                 37.94 K - 4.06x slower +19.86 μs

##### With input Small 160 B (typical RTP payload size) #####
Name                                 ips        average  deviation         median         99th %
Pattern match function LUT      376.15 K        2.66 μs    �63.07%        2.50 μs        3.37 μs
Map LUT in state                264.35 K        3.78 μs    �54.46%        3.57 μs        5.10 μs
Module attribute map LUT        257.84 K        3.88 μs    �55.39%        3.61 μs        7.98 μs
FFmpeg NIFs                     184.34 K        5.42 μs   �515.00%        4.48 μs       28.31 μs

Comparison:
Pattern match function LUT      376.15 K
Map LUT in state                264.35 K - 1.42x slower +1.12 μs
Module attribute map LUT        257.84 K - 1.46x slower +1.22 μs
FFmpeg NIFs                     184.34 K - 2.04x slower +2.77 μs
```
