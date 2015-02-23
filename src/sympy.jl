module SymPy

export sympy2mxpr, mxpr2sympy

importall SJulia

import SJulia: mxpr

using PyCall

# Author: Francesco Bonazzi

## Convert SymPy to Mxpr

@pyimport sympy
@pyimport sympy.core as sympy_core

const SympySymbol = sympy_core.symbol["Symbol"]
const SympyAdd = sympy_core.add["Add"]
const SympyMul = sympy_core.mul["Mul"]
const SympyPow = sympy_core.power["Pow"]
const SympyNumber = sympy_core.numbers["Number"]
const SympySin = sympy.functions["sin"]

const conv_dict = Dict(
    SympyAdd => :Plus,
    SympyMul => :Times,
    SympyPow => :Power,
    SympySin => :Sin                   
)

function sympy2mxpr(exp_tree)
    if (pytypeof(exp_tree) in keys(conv_dict))
        return SJulia.mxpr(conv_dict[pytypeof(exp_tree)], map(sympy2mxpr, exp_tree[:args])...)
    end
    if pytypeof(exp_tree) == SympySymbol
        return Symbol(exp_tree[:name])
    end
    if pyisinstance(exp_tree, SympyNumber)
        if exp_tree[:is_Integer]
            return convert(BigInt, exp_tree)
        end
        if exp_tree[:is_Rational]
            return convert(Rational{BigInt}, exp_tree)
        end 
        return convert(FloatingPoint, exp_tree)
    end
end


# TESTS

function test_sympy2mxpr()
    x, y, z = sympy.symbols("x y z")
    add1 = sympy.Add(x, y, z, 3)
    @assert sympy2mxpr(add1) == mxpr(:Plus, 3, :x, :y, :z)
    mul1 = sympy.Mul(x, y, z, -2)
    @assert sympy2mxpr(mul1) == mxpr(:Times, -2, :x, :y, :z)
    add2 = sympy.Add(x, mul1)
    @assert sympy2mxpr(add2) == mxpr(:Plus, :x, mxpr(:Times, -2, :x, :y, :z))
end

## Convert Mxpr to SymPy

const conv_rev = Dict(
    :Plus => sympy.Add,
    :Times => sympy.Mul,
    :Power => sympy.Pow,
    :Sin => sympy.sin
)   

function mxpr2sympy(mex)
    if !isa(mex, SJulia.Mxpr)
        if isa(mex, Symbol)
            return sympy.Symbol(mex)
        end
        if isa(mex, Number)
            return mex
        end
    end
    if mex.head in keys(conv_rev)
        return conv_rev[mex.head](map(mxpr2sympy, mex.args)...)
    end
end

# TEST

function test_mxpr2sympy()
    me1 = mxpr(:Plus, :a, :b,  mxpr(:Times, -3, :z, mxpr(:Power, :x, 2)))
    me2 = mxpr(:Times, 2, :x, :y)
    @assert sympy2mxpr(mxpr2sympy(me1)) == me1
    @assert sympy2mxpr(mxpr2sympy(me2)) == me2
end

end  # module SJulia.SymPy
