"""
╔═══════════════════════════════════════════════════════════════════════════════╗
║                       RESONANCE MEASUREMENT ENGINE                            ║
║                       Julia Web3 Implementation v1.0                          ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║    ┌──────────────────────────────────────────────────────────────┐         ║
║    │                    RESONANCE DETECTION                        │         ║
║    │                                                                │         ║
║    │     Input Signal          Resonance Spectrum                 │         ║
║    │     ∿∿∿∿∿∿∿∿∿           ┌────────────────┐                 │         ║
║    │        │                 │  ╱╲    ╱╲      │                 │         ║
║    │        ▼                 │ ╱  ╲  ╱  ╲     │                 │         ║
║    │     [FFT]──────────────►│╱    ╲╱    ╲    │                 │         ║
║    │                         └────────────────┘                  │         ║
║    │                              f₁  f₂  f₃                     │         ║
║    └──────────────────────────────────────────────────────────────┘         ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"""

using FFTW
using Statistics
using LinearAlgebra
using PythonCall

mutable struct ResonanceMeasurement
    frequencies::Vector{Float64}
    amplitudes::Vector{Float64}
    phase_coherence::Float64
    quality_factor::Float64
    
    function ResonanceMeasurement()
        new(Float64[], Float64[], 1.0, 10.0)
    end
end

function measure_resonance(rm::ResonanceMeasurement, signal::Vector)
    # Perform FFT
    fft_result = fft(signal)
    
    # Extract frequencies and amplitudes
    rm.frequencies = collect(1:length(fft_result)) / length(fft_result)
    rm.amplitudes = abs.(fft_result)
    
    # Find resonance peaks
    peaks = findall(x -> x > mean(rm.amplitudes) + std(rm.amplitudes), rm.amplitudes)
    
    # Calculate phase coherence
    if !isempty(peaks)
        rm.phase_coherence = mean(angle.(fft_result[peaks]))
    end
    
    # Calculate quality factor
    if length(peaks) > 0
        peak_freq = rm.frequencies[peaks[1]]
        bandwidth = estimate_bandwidth(rm.amplitudes, peaks[1])
        rm.quality_factor = peak_freq / bandwidth
    end
    
    return Dict(
        :resonance_frequencies => rm.frequencies[peaks],
        :quality_factor => rm.quality_factor,
        :coherence => rm.phase_coherence
    )
end

function estimate_bandwidth(amplitudes, peak_idx)
    peak_amp = amplitudes[peak_idx]
    half_power = peak_amp / sqrt(2)
    
    # Find 3dB points
    left_idx = findlast(x -> x <= half_power, amplitudes[1:peak_idx])
    right_idx = findfirst(x -> x <= half_power, amplitudes[peak_idx:end])
    
    bandwidth = (right_idx !== nothing && left_idx !== nothing) ? 
                abs(right_idx - left_idx) / length(amplitudes) : 0.1
    
    return max(bandwidth, 0.01)
end

export ResonanceMeasurement, measure_resonance