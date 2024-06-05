"""
    mutable struct Term

A `Term` object records a term that looks like ``Uc^{(p_1)}_{o_1}c^{(p_2)}_{o_2}… c^{(p_l)}_{o_l}`` in an operator

# Fields
- `coeff :: ComplexF64` records the coefficient ``U``
- `cstr :: Vector{Int64}` is a length-``2l`` vector ``(p_1,o_1,p_2,o_2,… p_l,o_l)`` recording the operator string

# Method 

It can be generated by the function

    function Term(coeff :: ComplexF64, cstr :: Vector{Int64}) :: ComplexF64 
"""
mutable struct Term 
    coeff :: ComplexF64 
    cstr :: Vector{Int64}
end 

function zero( x :: Type{Vector{Term}})
    return Term[]
end

"""
    function *(fac :: Number, tms :: Vector{Term}) :: Vector{Term}
    function -(tms :: Vector{Term}) :: Vector{Term}
    function *(tms :: Vector{Term}, fac :: Number) :: Vector{Term}
    function /(tms :: Vector{Term}, fac :: Number) :: Vector{Term}

Return the product of a collection of terms with a number. 
"""
function *(fac :: Number, tms :: Vector{Term})
    return [ Term(fac * tm.coeff, tm.cstr) for tm in tms ]
end
function -(tms :: Vector{Term})
    return (-1) * tms
end
function *(tms :: Vector{Term}, fac :: Number)
    return fac * tms
end
function /(tms :: Vector{Term}, fac :: Number)
    return (1 / fac) * tms
end

"""
    function +(tms1 :: Vector{Term}, tms2 :: Vector{Term}) :: Vector{Term}
    function -(tms1 :: Vector{Term}, tms2 :: Vector{Term}) :: Vector{Term}

Return the naive sum of two series of terms by taking their union. 
"""
function +(tms1 :: Vector{Term}, tms2 :: Vector{Term})
    return [ tms1 ; tms2 ]
end
function -(tms1 :: Vector{Term}, tms2 :: Vector{Term})
    return tms1 + (-tms2)
end

"""
    function *(tms1 :: Vector{Term}, tms2 :: Vector{Term}) :: Vector{Term}

Return the naive product of two series of terms. The number of terms equals the product of the number of terms in `tms1` and `tms2`. For each term in `tms1` ``Uc^{(p_1)}_{o_1}…`` and `tms2` ``U'c^{(p'_1)}_{o'_1}…``, a new term is formed by taking ``UU'c^{(p_1)}_{o_1}… c^{(p'_1)}_{o'_1}…``
"""
function *(tms1 :: Vector{Term}, tms2 :: Vector{Term})
    return vcat([ Term(tm1.coeff * tm2.coeff, [tm1.cstr ; tm2.cstr])
        for tm1 in tms1, tm2 in tms2 ]...)
end

function adjoint(tm :: Term)
    nc = length(tm.cstr)
    cstr1 = [ isodd(i) ? 1 - tm.cstr[nc - i] : tm.cstr[nc + 2 - i] for i = 1 : nc]
    return Term(conj(tm.coeff), cstr1)
end
"""
    function adjoint(tm :: Term) :: Term
    function adjoint(tms :: Vector{Term}) :: Vector{Term}

Return the Hermitian conjugate of a series of terms. For each term ``Uc^{(p_1)}_{o_1}c^{(p_2)}_{o_2}… c^{(p_l)}_{o_l}``, the adjoint is ``\\bar{U}c^{(1-p_l)}_{o_l}… c^{(1-p_2)}_{o_2}c^{(1-p_1)}_{o_1}``
"""
function adjoint(tms :: Vector{Term})
    return adjoint.(tms)
end


"""
    function NormalOrder(tm :: Term) :: Vector{Term}

rearrange a term such that 
- the creation operators must be commuted in front of the annihilation operator 
- the orbital index of the creation operators are in ascending order and the annihilation operators in descending order. 
return a list of terms whose result is equal to the original term. 
"""
function NormalOrder(tm :: Term)
    coeff0 = tm.coeff
    cstr0 = tm.cstr
    for i = 1 : 2 : length(cstr0) - 3
        if (cstr0[i] == -1) 
            cstr1 = deepcopy(cstr0)
            deleteat!(cstr1, i : i + 1)
            return(NormalOrder(Term(coeff0, cstr1)))
        end
        if (cstr0[i] == 0 && cstr0[i + 2] == 1)
            if (cstr0[i + 1] == cstr0[i + 3])
                cstr_nrm = deepcopy(cstr0)
                cstr_com = deepcopy(cstr0)
                cstr_nrm[i : i + 1], cstr_nrm[i + 2 : i + 3] = cstr_nrm[i + 2 : i + 3], cstr_nrm[i : i + 1]
                deleteat!(cstr_com, i : i + 3)
                return([ NormalOrder(Term(-coeff0, cstr_nrm)) ; 
                    NormalOrder(Term(coeff0, cstr_com))])
            else
                cstr_nrm = deepcopy(cstr0)
                cstr_nrm[i : i + 1], cstr_nrm[i + 2 : i + 3] = cstr_nrm[i + 2 : i + 3], cstr_nrm[i : i + 1]
                return(NormalOrder(Term(-coeff0, cstr_nrm)))
            end
        elseif (cstr0[i] == cstr0[i + 2])
            if (cstr0[i + 1] == cstr0[i + 3]) return Term[] end 
            if ((cstr0[i] == 1) == (cstr0[i + 1] > cstr0[i + 3]))
                cstr_nrm = deepcopy(cstr0)
                cstr_nrm[i : i + 1], cstr_nrm[i + 2 : i + 3] = cstr_nrm[i + 2 : i + 3], cstr_nrm[i : i + 1]
                return(NormalOrder(Term(-coeff0, cstr_nrm)))
            end
        end
    end
    if length(cstr0) == 0 return Term(coeff0, [-1, -1]) end
    return Term[tm]
end


"""
    function SimplifyTerms(tms :: Vector{Term}) :: Vector{Term}

simplifies the sum of terms such that 
- each term is normal ordered,
- like terms are combined, and terms with zero coefficients are removed.
"""
function SimplifyTerms(tms :: Vector{Term})
    tms1 = vcat(NormalOrder.(tms)...)
    sort!(tms1, by = tm -> sum([(tm.cstr[i] + π) * exp(i) for i in eachindex(tm.cstr)]))
    i = 1
    while i < length(tms1)
        if (tms1[i].cstr == tms1[i + 1].cstr)
            tms1[i].coeff += tms1[i + 1].coeff
            deleteat!(tms1, i + 1)
        else
            i = i + 1
        end
    end
    return filter(tm -> abs(tm.coeff) > 1E-13, tms1)
end