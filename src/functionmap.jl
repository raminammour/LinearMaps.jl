struct FunctionMap{T,F1,F2} <: LinearMap{T}
    f::F1
    fc::F2
    M::Int
    N::Int
    _ismutating::Bool
    _issymmetric::Bool
    _ishermitian::Bool
    _isposdef::Bool
end
function (::Type{FunctionMap{T}})(f::F1, fc::F2, M::Int, N::Int;
    ismutating::Bool = _ismutating(f), issymmetric::Bool = false, ishermitian::Bool=(T<:Real && issymmetric),
    isposdef::Bool = false) where {T,F1,F2}
    FunctionMap{T,F1,F2}(f, fc, M, N, ismutating, issymmetric, ishermitian, isposdef)
end

# additional constructors
(::Type{FunctionMap{T}})(f, M::Int; kwargs...) where {T} = FunctionMap{T}(f, nothing, M, M; kwargs...)
(::Type{FunctionMap{T}})(f, M::Int, N::Int; kwargs...) where {T} = FunctionMap{T}(f, nothing, M, N; kwargs...)
(::Type{FunctionMap{T}})(f, fc, M::Int; kwargs...) where {T} = FunctionMap{T}(f, fc, M, M; kwargs...)

# show
function Base.show(io::IO, A::FunctionMap{T}) where {T}
    print(io,"LinearMaps.FunctionMap{$T}($(A.f), $(A.fc), $(A.M), $(A.N); ismutating=$(A._ismutating), issymmetric=$(A._issymmetric), ishermitian=$(A._ishermitian), isposdef=$(A._isposdef))")
end

# properties
Base.size(A::FunctionMap) = (A.M, A.N)
Base.issymmetric(A::FunctionMap) = A._issymmetric
Base.ishermitian(A::FunctionMap) = A._ishermitian
Base.isposdef(A::FunctionMap) = A._isposdef
ismutating(A::FunctionMap) = A._ismutating
_ismutating(f) = first(methods(f)).nargs == 3

# multiplication with vector
function Base.A_mul_B!(y::AbstractVector, A::FunctionMap, x::AbstractVector)
    (length(x) == A.N && length(y) == A.M) || throw(DimensionMismatch())
    ismutating(A) ? A.f(y,x) : copy!(y,A.f(x))
    return y
end
function *(A::FunctionMap, x::AbstractVector)
    length(x) == A.N || throw(DimensionMismatch())
    if ismutating(A)
        y = similar(x, promote_type(eltype(A), eltype(x)), A.M)
        A.f(y,x)
    else
        y = A.f(x)
    end
    return y
end

function Base.At_mul_B!(y::AbstractVector, A::FunctionMap, x::AbstractVector)
    issymmetric(A) && return Base.A_mul_B!(y, A, x)
    (length(x) == A.M && length(y) == A.N) || throw(DimensionMismatch())
    if A.fc != nothing
        if !isreal(A)
            x = conj(x)
        end
        (ismutating(A) ? A.fc(y,x) : copy!(y, A.fc(x)))
        if !isreal(A)
            conj!(y)
        end
        return y
    else
        error("transpose not implemented for $A")
    end
end
function Base.At_mul_B(A::FunctionMap, x::AbstractVector)
    issymmetric(A) && return A*x
    length(x) == A.M || throw(DimensionMismatch())
    if A.fc != nothing
        if !isreal(A)
            x = conj(x)
        end
        if ismutating(A)
            y = similar(x, promote_type(eltype(A), eltype(x)), A.N)
            A.fc(y,x)
        else
            y = A.fc(x)
        end
        if !isreal(A)
            conj!(y)
        end
        return y
    else
        error("transpose not implemented for $A")
    end
end

function Base.Ac_mul_B!(y::AbstractVector, A::FunctionMap, x::AbstractVector)
    ishermitian(A) && return Base.A_mul_B!(y,A,x)
    (length(x) == A.M && length(y) == A.N) || throw(DimensionMismatch())
    if A.fc != nothing
        return (ismutating(A) ? A.fc(y, x) : copy!(y, A.fc(x)))
    else
        error("adjoint not implemented for $A")
    end
end
function Base.Ac_mul_B(A::FunctionMap, x::AbstractVector)
    ishermitian(A) && return A*x
    length(x) == A.M || throw(DimensionMismatch())
    if A.fc != nothing
        if ismutating(A)
            y = similar(x, promote_type(eltype(A), eltype(x)), A.N)
            A.fc(y,x)
        else
            y = A.fc(x)
        end
        return y
    else
        error("adjoint not implemented for $A")
    end
end
