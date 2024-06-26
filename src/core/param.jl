
"""
    SilentStd :: Bool = false 

a flag to determine whether logs of the FuzzifiED functions should be turned off. False by default. If you want to evaluate without log, put `FuzzifiED.SilentStd = true`. This parameter can be defined for each process separately. 
"""
SilentStd :: Bool= false

"""
    Libpath :: String = FuzzifiED_jll.LibpathFuzzifiED

define where the Fortran library are compiled. You do not need to modify that by yourself. However, if you compile the Fortran codes by yourself, you need to point this to your compiled library. 
"""
Libpath :: String = FuzzifiED_jll.LibpathFuzzifiED

"""
    NumThreads :: Int = Threads.nthreads()

an integer to define how many threads OpenMP uses. By default, it is the same as the number of threads in Julia. If you use Jupyter notebooks, which by default uses one core only, you may need to define this by hand, _e.g._, `FuzzifiED.NumThreads = 8`. This parameter can be defined for each process separately. 
"""
NumThreads :: Int = Threads.nthreads()

"""
    ElementType :: DataType = ComplexF64

set the default type of the operator elements, either `ComplexF64` or `Float64`. `ComplexF64` by default. 
"""
ElementType :: DataType = ComplexF64