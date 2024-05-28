""" 
    function GetIsingQnu(nm :: Int64) :: @NamedTuple{qnu_o :: Vector{Vector{Int64}}, qnu_name :: Vector{String}, modul :: Vector{Int64}}

returns the diagonal quantum numbers, _i.e._, particle number ``N_e``, angular momentum ``L_z`` and Cartans of the ``\\mathrm{Sp}(N)`` symmetry, of the fuzzy sphere Ising model. 

# Arguments 

- `nm :: Int64` is the number of orbitals ; 
- `nf :: Int64` is the number of flavours ; 

# Output

A named tuple with three elements that can be directly fed into [`SitesFromQN`](@ref)

- `qnu_o :: Vector{Vector{Int64}}` stores the charge of each orbital under each conserved quantity. See [`Confs`](@ref Confs(no :: Int64, qnu_s :: Vector{Int64}, qnu_o :: Vector{Any} ; nor :: Int64 = div(no, 2), modul :: Vector{Int64} = fill(1, length(qnu_s)))) for detail.
- `qnu_name :: Vector{String}` stores the name of each quantum number.
- `modul :: Vector{Int64}` stores the modulus of each quantum number, 1 if no modulus. 

"""
function GetSpnQnu(nm :: Int64, nf :: Int64)
    no = nf * nm
    qnu_o = []
    qnu_name = Vector{String}(undef, 0)
    modul = Vector{Int64}(undef, 0)
    # Record the number of electrons
    push!(qnu_o, fill(1, no)) 
    push!(qnu_name, "N_e")
    push!(modul, 1)
    # Record the angular momentum
    push!(qnu_o, [ div(o - 1, nf) for o = 1 : no ]) 
    push!(qnu_name, "L_z")
    push!(modul, 1)
    # Record the Cartan 
    for f = 0 : div(nf, 2) - 1
        push!(qnu_o, vcat([ mod(f1, nf) == f ? 2 : (mod(f1, nf) == f + nf / 2 ? 0 : 1) for f1 = 0 : nf - 1, m1 = 1 : nm]...))
        push!(qnu_name, "S_z" * string(f + 1))
        push!(modul, 1)
    end
    return (qnu_o = qnu_o, qnu_name = qnu_name, modul = modul)
end

"""
    function GetSpnConfs(nm :: Int64, nf :: Int64, ne :: Int64 ; lz :: Float64 = 0.0, sz :: Vector{Int64}) :: Confs

Return the configurations with conserved particle number ``N_e``, angular momentum ``L_z`` and Cartans of the ``\\mathrm{Sp}(N)`` symmetry 
```math
\\begin{aligned}
N_e&=\\sum_{mf}n_{mf}\\\\
L_z&=\\sum_{mf}mn_{mf}\\\\
S_{z,i}&=\\sum_m (n_{m,i}-n_{m,i+N_f/2})&i&=1,\\dots,N_f/2
\\end{aligned}
```

# Arguments

- `nm :: Int64` is the number of orbitals.
- `nf :: Int64` is the number of flavours.
- `ne :: Int64` is the number of electrons.
- `lz :: Float64` is the angular momentum. Facultive, 0 by default. 
- `sz :: Vector{Int64}` is ``N_f/2`` numbers that give ``\\mathrm{Sp}(N)`` Cartan. Facultive, a vector of ``N_f/2`` zeros by default. 
"""
function GetSpnConfs(nm :: Int64, nf :: Int64, ne :: Int64 ; lz :: Float64 = 0.0, sz :: Vector{Int64} = fill(0, div(nf, 2)))
    no = nf * nm
    s = .5 * (nm - 1)
    qnu_s = Vector{Int64}(undef, 0)
    push!(qnu_s, ne) 
    push!(qnu_s, Int(ne * s + lz))
    for f = 0 : div(nf, 2) - 1
        push!(qnu_s, ne + sz[f + 1])
    end
    qnu = GetSpnQnu(nm, nf)
    return Confs(no, qnu_s, qnu.qnu_o)
end

"""
    function GetSpnBasis(cfs :: Confs, nf :: Int64 ; qn_p :: Int64 = 0, qn_r :: Int64 = 0, qn_z :: Vector{Int64}, qn_x :: Vector{Int64} :: Basis

Return the basis with conserved parity ``\\mathscr{P}``, ``\\pi``-rotation along ``y``-axis ``\\mathscr{R}``, and flavour symmetries ``\\mathscr{Z}_i,\\mathscr{X}_i`` from the configurations already generated. Quantum numbers set to zero signify that they are not conserved. 

```math
\\begin{aligned}
\\mathscr{P}:c^{\\dagger}_{mf}&\\mapsto c_{m,f+N_f/2},&c^{\\dagger}_{m,f+N_f/2}&\\mapsto-c_{m,f}\\\\
\\mathscr{R}:c^{\\dagger}_{mf}&\\mapsto c^{\\dagger}_{-m,f}\\\\
\\mathscr{Z}_i:c^{\\dagger}_{mi}&\\mapsto c^{\\dagger}_{m,i+N_f/2}&c^{\\dagger}_{m,i+N_f/2}&\\mapsto-c^{\\dagger}_{m,i},&i=1,2,\\dots,N_f/2\\\\
\\mathscr{X}_i:c^{\\dagger}_{m,2i-1}&\\leftrightarrow c^{\\dagger}_{m,2i}&c^{\\dagger}_{m,2i-1+N_f/2}&\\leftrightarrow c^{\\dagger}_{m,2i+N_f/2},&i=1,2,\\dots,N_f/4\\\\
\\end{aligned}
```
Note that sometimes some ``\\mathscr{Z}_i`` and ``\\mathscr{X}_i`` cannot be implemented at the same time. 

# Arguments

- `cfs :: Confs` is the configurations generated by [`GetIsingConfs`](@ref).
- `nf :: Int64` is the number of flavours.
- `qn_p :: Int64` is quantum number for parity transformation. Facultive, 0 by default.
- `qn_r :: Int64` is the quantum number for  ``\\pi`` rotation along ``y``-axis compared with the ground state. Facultive, 0 by default.
- `qn_z :: Vector{Int64}` is ``N_f/2`` numbers that give ``\\mathscr{Z}_i`` flavour symmetry. Facultive, all 0 by default.
- `qn_x :: Vector{Int64}` is ``N_f/4`` numbers that give ``\\mathscr{X}_i`` flavour symmetry. Facultive, all 0 by default.
"""
function GetSpnBasis(cfs :: Confs, nf :: Int64 ; qn_p :: Int64 = 0, qn_r :: Int64 = 0, qn_z :: Vector{Int64} = fill(0, div(nf, 2)), qn_x :: Vector{Int64} = fill(0, div(nf, 4)))
    no = cfs.no
    nm = div(no, nf)
    cyc = fill(2, 2 + div(nf, 2) + div(nf, 4)) # Input three Z_2 symmetries 
    qnz_s = ComplexF64[ qn_p ; qn_r ; qn_z ; qn_x ] # Quantum numbers are all positive 
    # Initialise the vectors
    perm_o = []
    ph_o = []
    fac_o = []

    # Record the parity
    push!(perm_o, [begin 
            f1 = mod(o - 1, nf)
            o + div(nf, 2) * (f1 < div(nf, 2) ? 1 : -1)
        end for o = 1 : no ])
    push!(ph_o, fill(1, no))
    push!(fac_o, [ ComplexF64(1) * (mod(o - 1, nf) < div(nf, 2) ? 1 : -1) for o = 1 : no ])

    # Record the pi-rotation 
    push!(perm_o, [begin 
            f1 = mod(o - 1, nf) ; m1 = div(o - 1, nf)
            1 + f1 + nf * (nm - 1 - m1)
        end for o = 1 : no])
    push!(ph_o, fill(0, no)) 
    push!(fac_o, fill(ComplexF64(1), no)) 

    # Record the Z flavour symmetry
    for f = 0 : div(nf, 2) - 1
        push!(perm_o, [begin 
                f1 = mod(o - 1, nf)
                o + div(nf, 2) * (f1 == f ? 1 : (f1 == f + div(nf, 2) ? -1 : 0))
            end for o = 1 : no])
        push!(ph_o, fill(0, no))
        push!(fac_o, [ ComplexF64(1) * (mod(o - 1, nf) == f ? -1 : 1) for o = 1 : no ])
    end

    # Record the X flavour symmetry
    for f = 0 : 2 : div(nf, 2) - 2
        push!(perm_o, [begin 
                f1 = mod(o - 1, div(nf, 2))
                o + (f1 == f ? 1 : (f1 == f + 1 ? -1 : 0))
            end for o = 1 : no])
        push!(ph_o, fill(0, no))
        push!(fac_o, fill(ComplexF64(1), no))
    end

    return Basis(cfs, qnz_s, cyc, perm_o, ph_o, fac_o)
end

"""
    function GetIdDenIntTerms(nm :: Int64, nf :: Int64, ps_pot :: Vector) :: Vector{Term}

Returns the terms for the Hubbard density-density interaction 

```math
\\sum_{m_1m_2m_3m_4ff'}2U_{m_1m_2m_3m_4}c^{\\dagger}_{m_1f}c^{\\dagger}_{m_2f'}c_{m_3f'}c_{m_4f}
```

from the pseudopotentials. 

# Arguments 

- `nm :: Int64` is the number of orbitals ``2s+1``.
- `nf :: Int64` is the number of flavours.
- `ps_pot :: Vector{Number}` is the pseudopotential of the hubbard interaction.
"""
function GetIdDenIntTerms(nm :: Int64, nf :: Int64, ps_pot :: Vector)
    no = nm * nf
    int_el = GetIntMatrix(nm, ps_pot)
    tms = Vector{Term}(undef, 0)
    # Go through all the m1-up, m2-down, m3-down, m4-up and m4 = m1 + m2 - m3
    for o1 = 1 : no
        m1 = div(o1 - 1, nf) + 1
        f1 = mod(o1 - 1, nf)
        for o2 = 1 : no 
            m2 = div(o2 - 1, nf) + 1
            f2 = mod(o2 - 1, nf)
            if (f1 < f2) continue end # f1 >= f2
            if (f1 == f2 && m1 <= m2) continue end 
            for m3 = 1 : nm 
                f3 = f2 
                o3 = nf * (m3 - 1) + f3 + 1
                f4 = f1
                m4 = m1 + m2 - m3 
                if (m4 <= 0 || m4 > nm) continue end
                o4 = (m4 - 1) * nf + f4 + 1
                val = int_el[m1, m2, m3] * 2. 
                if (f1 == f2) val -= int_el[m2, m1, m3] * 2. end
                if (abs(val) < 1E-15) continue end 
                push!(tms, Term(val, [1, o1, 1, o2, 0, o3, 0, o4]))
            end
        end
    end
    return tms
end

"""
    function GetSpnPairIntTerms(nm :: Int64, nf :: Int64, ps_pot :: Vector) :: Vector{Term}

Returns the terms for the ``\\mathrm{Sp}(N)`` pair-pair interaction 

```math
\\sum_{m_1m_2m_3m_4ff'}2U_{m_1m_2m_3m_4}c^{\\dagger}_{m_1f}c^{\\dagger}_{m_2,f+N_f/2}c_{m_3 f'+N_f/2}c_{m_4f'}
```

from the pseudopotentials. 

# Arguments 

- `nm :: Int64` is the number of orbitals.
- `nf :: Int64` is the number of flavours.
- `ps_pot :: Vector{Number}` is the pseudopotential of the hubbard interaction.
"""
function GetSpnPairIntTerms(nm :: Int64, nf :: Int64, ps_pot :: Vector)
    no = nm * nf
    int_el = GetIntMatrix(nm, ps_pot)
    tms = Vector{Term}(undef, 0)
    # Go through all the m1-up, m2-down, m3-down, m4-up and m4 = m1 + m2 - m3
    for o1 = 1 : no
        m1 = div(o1 - 1, nf) + 1
        f1 = mod(o1 - 1, nf)
        if (f1 >= div(nf, 2)) continue end
        for m2 = 1 : nm 
            f2 = f1 + div(nf, 2)
            o2 = (m2 - 1) * nf + f2 + 1
            for o3 = 1 : no
                m3 = div(o3 - 1, nf) + 1
                f3 = mod(o3 - 1, nf)
                if (f3 < div(nf, 2)) continue end 
                m4 = m1 + m2 - m3 
                f4 = f3 - div(nf, 2)
                if (m4 <= 0 || m4 > nm) continue end
                o4 = (m4 - 1) * nf + f4 + 1
                val = int_el[m1, m2, m3]
                if (abs(val) < 1E-15) continue end 
                push!(tms, Term(val, [1, o1, 1, o2, 0, o3, 0, o4]))
            end
        end 
    end
    return tms
end

"""
    function GetSpnC2Terms(nm :: Int64, nf :: Int64) :: Vector{Term}

Returns the quadratic Casimir ``C_2`` of the ``\\mathrm{Sp}(N)`` symmetry.

# Arguments 

- `nm :: Int64` is the number of orbitals.
- `nf :: Int64` is the number of flavours.
"""
function GetSpnC2Terms(nm :: Int64, nf :: Int64) 
    no = nm * nf
    tms = GetIdDenIntTerms(nm, nf, [isodd(m) ? -.5 : 0 for m = 1 : nm]) + GetSpnPairIntTerms(nm, nf, [isodd(m) ? -1.0 : 0 for m = 1 : nm])
    for o1 = 1 : no 
        push!(tms, Term(.25 + .25 * nf, [1, o1, 0, o1]))
        for o2 = o1 + 1 : no 
            push!(tms, Term(.5, [1, o1, 1, o2, 0, o2, 0, o1]))
        end
    end
    return tms
end