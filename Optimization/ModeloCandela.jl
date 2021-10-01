using JuMP
using Cbc

# El conjunto i contiene el elemento j
A=rand(10,10).<0.7

I=1:10
J=1:10

m = Model(Cbc.Optimizer)

@variable(m, x[J], Bin)

for i in I
    @constraint(m, sum([x[j]*(A[i,j] if A[i,j]>0.3 else 0) for j in J]) >= 1)
end

@objective(m, Min, sum([x[j] for j in J]))

optimize!(m)

print(getvalue.(x))