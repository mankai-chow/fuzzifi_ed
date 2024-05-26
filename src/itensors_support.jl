"""
    function ConfsFromSites(sites :: Vector{Index{Vector{Pair{QN, Int64}}}}, qn_s :: QN)

# Arguments 

* `sites :: Vector{Index{Vector{Pair{QN, Int64}}}}` is a `Sites` object, where the modulus-``\\pm 1`` quantum numbers will be taken out, and QNs with other modulus will be discarded automatically. Also note that only `Fermion` site type is supported, and the quantum numbers of the `0` state must be all zero. Note that this will subject to the limitation in ITensors that the number of conserved quantities must be less than 4. 
* `qn_s :: QN` is a `QN` object that specifies the the quantum number of the selected configuration.

"""
function ConfsFromSites(sites :: Vector{Index{Vector{Pair{QN, Int64}}}}, qn_s :: QN)
    no = length(sites)
    qn_names = []
    for site in sites 
        for qn in qn(site, 2)
            if abs(qn.modulus) != 1 continue end
            if qn.name in qn_names continue end
            push!(qn_names, qn.name)
        end
    end
    qnu_o = []
    for qn_name in qn_names 
        qnu_oi = []
        for site in sites 
            push!(qnu_oi, val(qn(site, 2), qn_name))
        end
        push!(qnu_o, qnu_oi)
    end
    qnu_s = [ val(qn_s, qn_name) for qn_name in qn_names ]
    return Confs(no, qnu_s, qnu_o)
end 

"""
    function ConfsFromSites(sites :: Vector{Index{Vector{Pair{QN, Int64}}}}, cf_ref :: Vector{Int64})

* `sites :: Vector{Index{Vector{Pair{QN, Int64}}}}` is a `Sites` object, where the modulus-``\\pm 1`` quantum numbers will be taken out, and QNs with other modulus will be discarded automatically. Also note that only `Fermion` site type is supported, and the quantum numbers of the `0` state must be all zero. Note that this will subject to the limitation in ITensors that the number of conserved quantities must be less than 4. 
* `cf_ref :: Vector{Int64})` is a reference configuration composed of `0` and `1` in `ITensors` format.

"""
function ConfsFromSites(sites :: Vector{Index{Vector{Pair{QN, Int64}}}}, cf_ref :: Vector{Int64})
    no = length(sites)
    qn_names = []
    for site in sites 
        for qn in qn(site, 2)
            if abs(qn.modulus) != 1 continue end
            if qn.name in qn_names continue end
            push!(qn_names, qn.name)
        end
    end
    qnu_o = []
    for qn_name in qn_names 
        qnu_oi = []
        for site in sites 
            push!(qnu_oi, val(qn(site, 2), qn_name))
        end
        push!(qnu_o, qnu_oi)
    end
    qnu_s = [ cf_ref' * qnu_o[i] for i = 1 : length(qnu_o) ]
    return Confs(no, qnu_s, qnu_o)
end 

"""
    function OperatorFromOpSum(bsd :: Basis, bsf :: Basis, opsum :: Sum{Scaled{ComplexF64, Prod{Op}}} ; red_q :: Int64 = 0, sym_q :: Int64 = 0)

Note that the only operators supported are `"C"`, `"Cdag"` `"N"` and `"I"`.
"""
function OperatorFromOpSum(bsd :: Basis, bsf :: Basis, opsum :: Sum{Scaled{ComplexF64, Prod{Op}}} ; red_q :: Int64 = 0, sym_q :: Int64 = 0)
    tms = Vector{Term}(undef,0)
    for i = 1 : length(opsum)
        cstr = []
        for j = 1 : length(opsum[i])
            optype = opsum[i][j].which_op
            opsite = opsum[i][j].sites[1]
            if optype == "Cdag"
                append!(cstr, [1, opsite])
            elseif optype == "C"
                append!(cstr, [0, opsite])
            elseif optype == "N"
                append!(cstr, [1, opsite, 0, opsite])
            elseif optype == "I"
                append!(cstr, [-1, -1])
            else 
                print("The only operator supported are C, Cdag and N")
            end
        end 
        if length(opsum[i]) == 0
            append!(cstr, [-1, -1])
        end
        fac = coefficient(opsum[i])
        push!(tms, Term(fac, cstr))
    end
    return Operator(bsd, bsf, tms ; red_q, sym_q)
end