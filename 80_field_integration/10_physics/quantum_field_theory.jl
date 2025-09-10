#!/usr/bin/env julia
"""
Quantum Field Theory Integration
Manifests QFT concepts in applied scientific programming
Demonstrates field operators, creation/annihilation, and vacuum states
"""

using LinearAlgebra
using SparseArrays

# Field operator representation
struct FieldOperator
    mode::Int
    type::Symbol  # :creation or :annihilation
    momentum::Vector{Float64}
    spin::Float64
end

# Quantum field state
struct QuantumFieldState
    occupation_numbers